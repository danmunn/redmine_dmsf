#!/usr/bin/ruby -W0

# encoding: utf-8
#
# Redmine Xapian is a Redmine plugin to allow attachments searches by content.
#
# Copyright © 2010    Xabier Elkano
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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
# Available languages are danish dutch english finnish french german german2 hungarian italian kraaij_pohlmann lovins
# norwegian porter portuguese romanian russian spanish swedish turkish:
$stem_langs	= ['english']

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
$databasepath = nil
$env = 'production'
$retryfailed = nil

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
  'application/vnd.oasis.opendocument.presentation' => 'odp',
  'application/javascript' => 'js'
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

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: xapian_indexer.rb [OPTIONS...]'
  opts.separator('')
  opts.separator('Index Redmine DMS documents')
  opts.separator('')  
  opts.separator('')
  opts.separator('Options:')
  opts.on('-s', '--stemming_lang a,b,c', Array,'Comma separated list of stemming languages for indexing') { |s| $stem_langs = s }  
  opts.on('-v', '--verbose',            'verbose') {$verbose += 1}}
  opts.on('-e', '--environment ENV',    'Rails ENVIRONMENT (development, testing or production), default production') { |e| $env = e}
  opts.on('-t', '--temp-dir PATH',      'Temporary directory for indexing'){ |t| $tempdir = t }
  opts.on('-V', '--version',            'show version and exit') { puts VERSION; exit}
  opts.on('-h', '--help',               'show help and exit') { puts opts; exit }
  opts.on('-R', '--retry-failed', 'retry files which omindex failed to extract text') { $retryfailed = 1 }
  opts.separator('')
  opts.separator('Examples:')
  opts.separator('  xapian_indexer.rb -s english,italian -v')
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

def supported_mime_type(entry)
  mtype = Redmine::MimeType.of(entry)
  MIME_TYPES.include?(mtype) || Redmine::MimeType.is_type?('text', mtype)
end

def convert_to_text(fpath, type)
  text = nil
  return text if !File.exist?(FORMAT_HANDLERS[type].split(' ').first)
  case type
    when 'pdf'    
      text = `#{FORMAT_HANDLERS[type]} #{fpath} -`
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
      text = `#{FORMAT_HANDLERS[type]} #{fpath}`
  end
  return text
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

# Indexing documents
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
  cmd = "#{$omindex} -s #{lang} --db #{databasepath} #{filespath} --url / --depth-limit=0"
  cmd << ' -v' if $verbose > 0
  cmd << ' --retry-failed' if $retryfailed
  log cmd
  system_or_raise (cmd)
end
log 'Redmine DMS documents indexed'

exit 0