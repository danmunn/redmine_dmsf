#!/usr/bin/ruby -W0

# encoding: utf-8
#
# Redmine Xapian is a Redmine plugin to allow attachments searches by content.
#
# Copyright (C) 2010  Xabier Elkano
# Copyright (C) 2015  Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

################################################################################################
# BEGIN Configuration parameters
# Configure the following parameters (most of them can be configured through the command line):
################################################################################################

# Redmine installation directory
$redmine_root = '/opt/redmine'

# DMSF document location $redmine_root/$files
$files = 'dmsf'

# scriptindex binary path 
$scriptindex  = '/usr/bin/scriptindex'

# omindex binary path
$omindex      = '/usr/bin/omindex'

# Directory containing xapian databases for omindex (Attachments indexing)
$dbrootpath   = '/var/tmp/dmsf-index'

# Verbose output, values of 0 no verbose, greater than 0 verbose output
$verbose      = 0

# Define stemmed languages to index attachments Eg. [ 'english', 'italian', 'spanish' ]
# Repository database will be always indexed in english
# Available languages are danish dutch english finnish french german german2 hungarian italian kraaij_pohlmann lovins norwegian porter portuguese romanian russian spanish swedish turkish:  
$stem_langs	= ['english']

# Project identifiers that will be indexed eg. [ 'prj_id1', 'prj_id2' ]
$projects	= [ 'prj_id1', 'prj_id2' ]

# Temporary directory for indexing, it can be tmpfs
$tempdir	= '/tmp'

# Binaries for text conversion
$pdftotext = '/usr/bin/pdftotext -enc UTF-8'
$antiword	 = '/usr/bin/antiword'
$catdoc		 = '/usr/bin/catdoc'
$xls2csv	 = '/usr/bin/xls2csv'
$catppt		 = '/usr/bin/catppt'
$unzip		 = '/usr/bin/unzip -o'
$unrtf		 = '/usr/bin/unrtf -t text 2>/dev/null'

################################################################################################
# END Configuration parameters
################################################################################################

$environment = File.join($redmine_root, 'config/environment.rb')
$projects = Array.new
$databasepath = nil
$repositories = nil
$onlyfiles = nil
$onlyrepos = nil
$env = 'production'
$resetlog = nil

MIME_TYPES = {
  'application/pdf' => 'pdf',
  'application/rtf' => 'rtf',
  'application/msword' => 'doc',
  'application/vnd.ms-excel' => 'xls',
  'application/vnd.ms-powerpoint' => 'ppt,pps',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'xlsx',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'pptx',
  'application/vnd.openxmlformats-officedocument.presentationml.slideshow' => 'ppsx',
  'application/vnd.oasis.opendocument.spreadsheet' => 'ods',
  'application/vnd.oasis.opendocument.text' => 'odt',
  'application/vnd.oasis.opendocument.presentation' => 'odp'
}.freeze


FORMAT_HANDLERS = {
  'pdf' => $pdftotext,
  'doc' => $catdoc,
  'xls' => $xls2csv,
  'ppt,pps' => $catppt,
  'docx' => $unzip,
  'xlsx' => $unzip,
  'pptx' => $unzip,
  'ppsx' => $unzip,
  'ods'  => $unzip,
  'odt'  => $unzip,
  'odp'  => $unzip,
  'rtf' => $unrtf
}.freeze

require 'optparse'

VERSION = '0.1'
SUPPORTED_SCM = %w(Subversion Darcs Mercurial Bazaar Git Filesystem)

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: xapian_indexer.rb [OPTIONS...]'
  opts.separator('')
  opts.separator('Index redmine files and repositories')
  opts.separator('')  
  opts.separator('')
  opts.separator('Options:')
  opts.on('-p', '--projects a,b,c', Array, 'Comma separated list of projects to index') { |p| $projects = p }
  opts.on('-s', '--stemming_lang a,b,c', Array,'Comma separated list of stemming languages for indexing') { |s| $stem_langs = s }  
  opts.on('-v', '--verbose',            'verbose') {$verbose += 1}
  opts.on('-f', '--files',              'Only index Redmine attachments') { $onlyfiles = 1 }
  opts.on('-r', '--repositories',       'Only index Redmine repositories') { $onlyrepos = 1 }
  opts.on('-e', '--environment ENV',    'Rails ENVIRONMENT (development, testing or production), default production') { |e| $env = e}
  opts.on('-t', '--temp-dir PATH',      'Temporary directory for indexing'){ |t| $tempdir = t }  
  opts.on('-x', '--resetlog',           'Reset index log'){  $resetlog = 1 }
  opts.on('-V', '--version',            'show version and exit') { puts VERSION; exit}
  opts.on('-h', '--help',               'show help and exit') { puts opts; exit }  
  opts.separator('')
  opts.separator('Examples:')
  opts.separator('  xapian_indexer.rb -f -s english,italian -v')
  opts.separator('  xapian_indexer.rb -p project_id -x -t /tmpfs -v')
  opts.separator('')
  opts.summary_width = 25
end

optparse.parse!

ENV['RAILS_ENV'] = $env

STATUS_SUCCESS = 1
STATUS_FAIL = -1
    
ADD_OR_UPDATE = 1
DELETE = 0
 
class IndexingError < StandardError; end

def repo_name(repository)
  repository.identifier.blank? ? 'main' : repository.identifier
end

def indexing(databasepath, project, repository)
    log "Fetch changesets: #{project.name} - #{repo_name(repository)}"    
    repository.fetch_changesets    
    repository.reload.changesets.reload    

    latest_changeset = repository.changesets.first    
    return unless latest_changeset    

    log "Latest revision: #{project.name} - #{repo_name(repository)} - #{latest_changeset.revision}"
    latest_indexed = Indexinglog.where(:repository_id => repository.id, :status => STATUS_SUCCESS).last
    Rails.logger.debug "Debug latest_indexed #{latest_indexed.inspect}"
    begin
      indexconf = Tempfile.new('index.conf', $tempdir)
      indexconf.write "url : field boolean=Q unique=Q\n"
      indexconf.write "body : index truncate=400 field=sample\n"
      indexconf.write "date: field=date\n"
      indexconf.close
      unless latest_indexed
        log "Repository #{repo_name(repository)} not indexed, indexing all"        
        indexing_all(databasepath, indexconf, project, repository)
      else
        log "Repository #{repo_name(repository)} indexed, indexing diff"        
        indexing_diff(databasepath, indexconf, project, repository, 
          latest_indexed.changeset, latest_changeset)
      end
      indexconf.unlink
    rescue IndexingError => e
      add_log(repository, latest_changeset, STATUS_FAIL, e.message)
    else
      add_log(repository, latest_changeset, STATUS_SUCCESS)
      log "Successfully indexed: #{project.name} - #{repo_name(repository)} - #{latest_changeset.revision}"
    end
end

def supported_mime_type(entry)
  mtype = Redmine::MimeType.of(entry)
  included = false
  included = MIME_TYPES.include?(mtype) || mtype.split('/').first.eql?('text') unless mtype.nil?  
  return included
end

def add_log(repository, changeset, status, message = nil)
  log = Indexinglog.where(:repository_id => repository.id).last
  unless log
    log = Indexinglog.new
    log.repository = repository
    log.changeset = changeset
    log.status = status
    log.message = message if message
    log.save!
    log "New log for repo #{repo_name(repository)} saved!"    
  else
    log.changeset_id=changeset.id
    log.status=status
    log.message = message if message
    log.save!
    log "Log for repo #{repo_name(repository)} updated!"    
  end
end

def update_log(repository, changeset, status, message = nil)
  log = Indexinglog.where(:repository_id => repository.id).last
  if log
    log.changeset_id = changeset.id
    log.status = status if status
    log.message = message if message
    log.save!
    log "Log for repo #{repo_name(repository)} updated!"    
  end
end

def delete_log(repository)
  Indexinglog.delete_all(:repository_id => repository.id)
  log "Log for repo #{repo_name(repository)} removed!"  
end

def walk(databasepath, indexconf, project, repository, identifier, entries)  
  return if entries.nil? || entries.size < 1
  log "Walk entries size: #{entries.size}"
  entries.each do |entry|
    log "Walking into: #{entry.lastrev.time}"
    if entry.is_dir?
      walk(databasepath, indexconf, project, repository, identifier, repository.entries(entry.path, identifier))
    elsif entry.is_file?
      add_or_update_index(databasepath, indexconf, project, repository, identifier, entry.path, 
        entry.lastrev, ADD_OR_UPDATE, MIME_TYPES[Redmine::MimeType.of(entry.path)]) if supported_mime_type(entry.path)	
    end
  end
end

def indexing_all(databasepath, indexconf, project, repository)  
  Rails.logger.info "Indexing all: #{repo_name(repository)}"
  if repository.branches
    repository.branches.each do |branch|
      log "Walking in branch: #{repo_name(repository)} - #{branch}"
      walk(databasepath, indexconf, project, repository, branch, repository.entries(nil, branch))
    end
  else
    log "Walking in branch: #{repo_name(repository)} - [NOBRANCH]"
    walk(databasepath, indexconf, project, repository, nil, repository.entries(nil, nil))
  end
  if repository.tags
    repository.tags.each do |tag|
      log "Walking in tag: #{repo_name(repository)} - #{tag}"
      walk(databasepath, indexconf, project, repository, tag, repository.entries(nil, tag))
    end
  end
end

def walkin(databasepath, indexconf, project, repository, identifier, changesets)
    log "Walking into #{changesets.inspect}"
    return unless changesets or changesets.size <= 0
    changesets.sort! { |a, b| a.id <=> b.id }

    actions = Hash::new
    # SCM actions
    #   * A - Add
    #   * M - Modified
    #   * R - Replaced
    #   * D - Deleted
    changesets.each do |changeset|
      log "Changeset changes for #{changeset.id} #{changeset.filechanges.inspect}"
      next unless changeset.filechanges
      changeset.filechanges.each do |change|        
        actions[change.path] = (change.action == 'D') ? DELETE : ADD_OR_UPDATE        
      end
    end
    return unless actions
    actions.each do |path, action|
      entry = repository.entry(path, identifier)
      if ((!entry.nil? && entry.is_file?) || action == DELETE)
        log("Error indexing path: #{path.inspect}, action: #{action.inspect}, identifier: #{identifier.inspect}", true) if (entry.nil? && action != DELETE)
        log "Entry to index #{entry.inspect}"
        lastrev = entry.lastrev unless entry.nil?
        add_or_update_index(databasepath, indexconf, project, repository, 
          identifier, path, lastrev, action, MIME_TYPES[Redmine::MimeType.of(path)]) if(supported_mime_type(path) || action == DELETE)
      end
    end
  end

def indexing_diff(databasepath, indexconf, project, repository, diff_from, diff_to)  
  if diff_from.id >= diff_to.id
    log "Already indexed: #{repo_name(repository)} (from: #{diff_from.id} to #{diff_to.id})"    
    return
  end

	log "Indexing diff: #{repo_name(repository)} (from: #{diff_from.id} to #{diff_to.id})"
	log "Indexing all: #{repo_name(repository)}"
  
	if repository.branches
    repository.branches.each do |branch|
    log "Walking in branch: #{repo_name(repository)} - #{branch}"
    walkin(databasepath, indexconf, project, repository, branch, repository.latest_changesets('', branch, diff_to.id - diff_from.id).select { |changeset| 
      changeset.id > diff_from.id and changeset.id <= diff_to.id})
	end
	else
    log "Walking in branch: #{repo_name(repository)} - [NOBRANCH]"
    walkin(databasepath, indexconf, project, repository, nil, repository.latest_changesets('', nil, diff_to.id - diff_from.id).select { |changeset| 
      changeset.id > diff_from.id and changeset.id <= diff_to.id})
	end
	if repository.tags
    repository.tags.each do |tag|
      log "Walking in tag: #{repo_name(repository)} - #{tag}"
      walkin(databasepath, indexconf, project, repository, tag, repository.latest_changesets('', tag, diff_to.id - diff_from.id).select { |changeset| 
          changeset.id > diff_from.id and changeset.id <= diff_to.id})
    end
	end
end

def generate_uri(project, repository, identifier, path)
	return url_for(:controller => 'repositories',
    :action => 'entry',
    :id => project.identifier,
    :repository_id => repository.identifier,
    :rev => identifier,
    :path => repository.relative_path(path),
    :only_path => true)
 end

def convert_to_text(fpath, type)
  text = nil
  return text if !File.exists?(FORMAT_HANDLERS[type].split(' ').first)
  case type
    when 'pdf'    
      text = "#{FORMAT_HANDLERS[type]} #{fpath} -"
    when /(xlsx|docx|odt|pptx)/i
      system "#{$unzip} -d #{$tempdir}/temp #{fpath} > /dev/null", :out=>'/dev/null'
      case type
        when 'xlsx'
          fout = "#{$tempdir}/temp/xl/sharedStrings.xml"
        when 'docx'
          fout = "#{$tempdir}/temp/word/document.xml"
        when 'odt'
          fout = "#{$tempdir}/temp/content.xml"
        when 'pptx'
          fout = "#{$tempdir}/temp/docProps/app.xml"
        end                
      begin
        text = File.read(fout)
        FileUtils.rm_rf("#{$tempdir}/temp") 
      rescue Exception => e
        log "Error: #{e.to_s} reading #{fout}", true
      end
    else
      text = "#{FORMAT_HANDLERS[type]} #{fpath}"
  end
  return text
end

def add_or_update_index(databasepath, indexconf, project, repository, identifier, 
    path, lastrev, action, type)  
  uri = generate_uri(project, repository, identifier, path)
  return unless uri
  text = nil
  if Redmine::MimeType.is_type?('text', path) #type eq 'txt' 
    text = repository.cat(path, identifier)
  else
    fname = path.split( '/').last.tr(' ', '_')
    bstr = nil
    bstr = repository.cat(path, identifier)
    File.open( "#{$tempdir}/#{fname}", 'wb+') do | bs |
      bs.write(bstr)
    end
    text = convert_to_text("#{$tempdir}/#{fname}", type) if File.exists?("#{$tempdir}/#{fname}") and !bstr.nil?
    File.unlink("#{$tempdir}/#{fname}")
  end  
  log "generated uri: #{uri}"
  log('Mime type text') if  Redmine::MimeType.is_type?('text', path)
  log "Indexing: #{path}"
  begin
    itext = Tempfile.new('filetoindex.tmp', $tempdir) 
    itext.write("url=#{uri.to_s}\n")
    if action != DELETE
      sdate = lastrev.time || Time.at(0).in_time_zone
      itext.write("date=#{sdate.to_s}\n")
      body = nil
      text.force_encoding('UTF-8')
      text.each_line do |line|        
        if body.blank? 
          itext.write("body=#{line}")
          body = 1
        else
          itext.write("=#{line}")
        end
      end      
    else      
      log "Path: #{path} should be deleted"
    end
    itext.close    
    log "TEXT #{itext.path} generated"
    log "Index command: #{$scriptindex} -s #{$user_stem_lang} #{databasepath} #{indexconf.path} #{itext.path}"
    system_or_raise("#{$scriptindex} -s english #{databasepath} #{indexconf.path} #{itext.path}")
    itext.unlink    
    log 'New doc added to xapian database'
  rescue Exception => e        
    log "Text not indexed beacause an error #{e.message}", true
  end
end

def log(text, error = false)  
  if error
    $stderr.puts text
  elsif $verbose > 0    
    $stdout.puts text
  end  
end

def system_or_raise(command)
  if $verbose > 0
    raise "\"#{command}\" failed" unless system command
  else
    raise "\"#{command}\" failed" unless system command, :out => '/dev/null'
  end
end

def find_project(prt)        
  project = Project.active.has_module(:repository).find_by_identifier(prt)
  if project
    log "Project found: #{project}"
  else
    log "Project #{prt} not found", true
  end    
  @project = project
end

log "Trying to load Redmine environment <<#{$environment}>>..."

begin
 require $environment
rescue LoadError
  log "Redmine #{$environment} cannot be loaded!! Be sure the redmine installation directory is correct!", true
  log 'Edit script and correct path', true
  exit 1
end

include Rails.application.routes.url_helpers

log "Redmine environment [RAILS_ENV=#{$env}] correctly loaded ..."

# Indexing files
unless $onlyrepos
  unless File.exist?($omindex)
    log "#{$omindex} does not exist, exiting...", true
    exit 1
  end
  $stem_langs.each do | lang |
    filespath = File.join($redmine_root, $files)
    unless File.directory?(filespath)
      log "An error while accessing #{filespath}, exiting...", true
      exit 1
    end
    databasepath = File.join($dbrootpath, lang)
    unless File.directory?(databasepath)
      log "#{databasepath} does not exist, creating ..."
      begin
        FileUtils.mkdir_p databasepath
      rescue Exception => e
        log e.message, true
        exit 1
      end      
    end    
    cmd = "#{$omindex} -s #{lang} --db #{databasepath} #{filespath} --url /"
    cmd << ' -v' if $verbose > 0
    log cmd
    system_or_raise (cmd)
  end
  log 'Redmine files indexed'
end

# Indexing repositories
unless $onlyfiles
  unless File.exist?($scriptindex)
    log "#{$scriptindex} does not exist, exiting...", true
    exit 1
  end
  databasepath = File.join($dbrootpath.rstrip, 'repodb')  
  unless File.directory?(databasepath)
    log "Db directory #{databasepath} does not exist, creating..."
    begin
      FileUtils.mkdir_p databasepath      
    rescue Exception => e
      log e.message, true
      exit 1
    end    
  end  
  $projects.each do |identifier|
    begin            
      project = Project.active.has_module(:repository).where(:identifier => identifier).preload(:repository).first
      raise ActiveRecord::RecordNotFound unless project
      log "Indexing repositories for #{project.name}..."
      repositories = project.repositories.select { |repository| repository.supports_cat? }
      repositories.each do |repository|        
        delete_log(repository) if ($resetlog)
        indexing(databasepath, project, repository)        
      end
    rescue ActiveRecord::RecordNotFound
      log "Project identifier #{identifier} not found or repository module not enabled, ignoring..."      
    end
  end
end

exit 0