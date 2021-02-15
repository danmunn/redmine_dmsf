#!/usr/bin/ruby -W0

# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2010    Xabier Elkano
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

require 'optparse'

########################################################################################################################
# BEGIN Configuration parameters
# Configure the following parameters (most of them can be configured through the command line):
########################################################################################################################

# Redmine installation directory
$redmine_root = File.expand_path('../../../../', __FILE__)

# DMSF document location $redmine_root/$files
$files = 'dmsf'

# scriptindex binary path 
$scriptindex = '/usr/bin/scriptindex'

# omindex binary path
$omindex = '/usr/bin/omindex'

# Directory containing Xapian databases for omindex (Attachments indexing)
$dbrootpath = File.expand_path('dmsf_index', $redmine_root)

# Verbose output, values of 0 no verbose, greater than 0 verbose output
$verbose = 0

# Define stemmed languages to index attachments Eg. [ 'english', 'italian', 'spanish' ]
# Available languages are danish, dutch, english, finnish, french, german, german2, hungarian, italian, kraaij_pohlmann,
# lovins, norwegian, porter, portuguese, romanian, russian, spanish, swedish and turkish.
$stem_langs	= ['english']

########################################################################################################################
# END Configuration parameters
########################################################################################################################

$environment = File.join($redmine_root, 'config/environment.rb')
$databasepath = nil
$env = 'production'
$retryfailed = nil

VERSION = '0.2'

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: xapian_indexer.rb [OPTIONS...]'
  opts.separator('')
  opts.separator('Index Redmine DMS documents')
  opts.separator('')  
  opts.separator('')
  opts.separator('Options:')
  opts.on('-s', '--stemming_lang a,b,c', Array,
          'Comma separated list of stemming languages for indexing') { |s| $stem_langs = s }
  opts.on('-v', '--verbose',            'verbose') {$verbose += 1}
  opts.on('-e', '--environment ENV',
          'Rails ENVIRONMENT (development, testing or production), default production') { |e| $env = e}
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
    raise "\"#{command}\" failed" unless system command, out: '/dev/null'
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
    rescue => e
      log e.message, true
      exit 1
    end
  end
  cmd = +"#{$omindex} -s #{lang} --db #{databasepath} #{filespath} --url / --depth-limit=0"
  cmd << ' -v' if $verbose > 0
  cmd << ' --retry-failed' if $retryfailed
  log cmd
  system_or_raise cmd
end
log 'Redmine DMS documents indexed'

exit 0