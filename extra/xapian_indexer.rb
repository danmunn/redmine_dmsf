#!/usr/bin/ruby -W0

# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Copyright © 2010    Xabier Elkano
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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
REDMINE_ROOT = File.expand_path('../../../', __dir__)

# DMSF document location $redmine_root/$files
FILES = 'dmsf'

# scriptindex binary path
SCRIPTINDEX = '/usr/bin/scriptindex'

# omindex binary path
# To index "non-text" files, use omindex filters
# e.g.: tesseract OCR engine as a filter for PNG files
OMINDEX = '/usr/bin/omindex'
# $omindex += " --filter=image/png:'tesseract -l chi_sim+chi_tra %f -'"
# $omindex += " --filter=image/jpeg:'tesseract -l chi_sim+chi_tra %f -'"

# Directory containing Xapian databases for omindex (Attachments indexing)
DBROOTPATH = File.expand_path('dmsf_index', REDMINE_ROOT)

# Verbose output, false/true
verbose = false

# Define stemmed languages to index attachments Eg. [ 'english', 'italian', 'spanish' ]
# Available languages are danish, dutch, english, finnish, french, german, german2, hungarian, italian, kraaij_pohlmann,
# lovins, norwegian, porter, portuguese, romanian, russian, spanish, swedish and turkish.
stem_langs	= ['english']

########################################################################################################################
# END Configuration parameters
########################################################################################################################

ENVIRONMENT = File.join(REDMINE_ROOT, 'config/environment.rb')
env = 'production'
retryfailed = false

VERSION = '0.2'

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: xapian_indexer.rb [OPTIONS...]'
  opts.separator('')
  opts.separator('Index Redmine DMS documents')
  opts.separator('')
  opts.separator('')
  opts.separator('Options:')
  opts.on('-s', '--stemming_lang a,b,c', Array,
          'Comma separated list of stemming languages for indexing') { |s| stem_langs = s }
  opts.on('-v', '--verbose', 'verbose') { verbose = true }
  opts.on('-e', '--environment ENV',
          'Rails ENVIRONMENT (development, testing or production), default production') { |e| env = e }
  opts.on('-V', '--version', 'show version and exit') do
    $stdout.puts VERSION
    exit
  end
  opts.on('-h', '--help', 'show help and exit') do
    $stdout.puts opts
    exit
  end
  opts.on('-R', '--retry-failed', 'retry files which omindex failed to extract text') { retryfailed = true }
  opts.separator('')
  opts.separator('Examples:')
  opts.separator('  xapian_indexer.rb -s english,italian -v')
  opts.separator('')
  opts.summary_width = 25
end

optparse.parse!

ENV['RAILS_ENV'] = env

def log(text, verbose, error: false)
  if error
    warn text
  elsif verbose
    $stdout.puts text
  end
end

def system_or_raise(command, verbose)
  if verbose
    raise StandardError, "\"#{command}\" failed" unless system(command)
  else
    raise StandardError, "\"#{command}\" failed" unless system(command, out: '/dev/null')
  end
end

log "Trying to load Redmine environment <<#{ENVIRONMENT}>>...", verbose

begin
  require ENVIRONMENT
rescue LoadError => e
  log e.message, verbose, error: true
  exit 1
end

log "Redmine environment [RAILS_ENV=#{env}] correctly loaded ...", verbose

# Indexing documents
stem_langs.each do |lang|
  filespath = Setting.plugin_redmine_dmsf['dmsf_storage_directory'] || File.join(REDMINE_ROOT, FILES)
  unless File.directory?(filespath)
    log "An error while accessing #{filespath}, exiting...", true
    exit 1
  end
  databasepath = File.join(DBROOTPATH, lang)
  unless File.directory?(databasepath)
    log "#{databasepath} does not exist, creating ...", verbose
    begin
      FileUtils.mkdir_p databasepath
    rescue StandardError => e
      log e.message, true
      exit 1
    end
  end
  cmd = +"#{OMINDEX} -s #{lang} --db #{databasepath} #{filespath} --url / --depth-limit=0"
  cmd << ' -v' if verbose
  cmd << ' --retry-failed' if retryfailed
  log cmd, verbose
  system_or_raise cmd, verbose
end
log 'Redmine DMS documents indexed', verbose

exit 0
