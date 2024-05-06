#!/usr/bin/ruby -W0

# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Xabier Elkano, Karel Pičman <karel.picman@kontron.com>
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

# DMSF document location REDMINE_ROOT/FILES
FILES = 'dmsf'

# omindex binary path
# To index "non-text" files, use omindex filters
# e.g.: tesseract OCR engine as a filter for PNG files
OMINDEX = '/usr/bin/omindex'
# OMINDEX += " --filter=image/png:'tesseract -l chi_sim+chi_tra %f -'"
# OMINDEX += " --filter=image/jpeg:'tesseract -l chi_sim+chi_tra %f -'"

# Directory containing Xapian databases for omindex (Attachments indexing)
db_root_path = File.expand_path('dmsf_index', REDMINE_ROOT)

# Verbose output, false/true
verbose = false

# Define stemmed languages to index attachments Eg. [ 'english', 'italian', 'spanish' ]
# Available languages are danish, dutch, english, finnish, french, german, german2, hungarian, italian, kraaij_pohlmann,
# lovins, norwegian, porter, portuguese, romanian, russian, spanish, swedish and turkish.
stem_langs	= ['english']

ENVIRONMENT = File.join(REDMINE_ROOT, 'config/environment.rb')
env = 'production'

########################################################################################################################
# END Configuration parameters
########################################################################################################################

retry_failed = false
no_delete = false
max_size = ''
overwrite = false

VERSION = '0.3'

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: xapian_indexer.rb [OPTIONS...]'
  opts.separator('')
  opts.separator("Index Redmine's DMS documents")
  opts.separator('')
  opts.separator('')
  opts.separator('Options:')
  opts.on('-d', '--index_db DB_PATH', 'Absolute path to index database according plugin settings in UI') do |db|
    db_root_path = db
  end
  opts.on('-s', '--stemming_lang a,b,c', Array, 'Comma separated list of stemming languages for indexing') do |s|
    stem_langs = s
  end
  opts.on('-v', '--verbose', 'verbose') do
    verbose = true
  end
  opts.on('-e', '--environment ENV', 'Rails ENVIRONMENT(development, testing or production), default production') do |e|
    env = e
  end
  opts.on('-V', '--version', 'show version and exit') do
    $stdout.puts VERSION
    exit
  end
  opts.on('-h', '--help', 'show help and exit') do
    $stdout.puts opts
    exit
  end
  opts.on('-R', '--retry-failed', 'retry files which omindex failed to extract text') do
    retry_failed = true
  end
  opts.on('-p', '--no-delete', 'skip the deletion of records corresponding to deleted files') do
    no_delete = true
  end
  opts.on('-m', '--max-size SIZE', "maximum size of file to index(e.g.: '5M', '1G',...)") do |m|
    max_size = m
  end
  opts.on('', '--overwrite', 'create the database anew instead of updating') do
    overwrite = true
  end
  opts.separator('')
  opts.separator('Examples:')
  opts.separator('  xapian_indexer.rb -s english,italian -v')
  opts.separator('  xapian_indexer.rb -d $HOME/index_db -s english,italian -v')
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
    system command, exception: true
  else
    system command, out: '/dev/null', exception: true
  end
end

log "Trying to load Redmine environment <<#{ENVIRONMENT}>>...", verbose

begin
  require ENVIRONMENT

  log "Redmine environment [RAILS_ENV=#{env}] correctly loaded ...", verbose

  # Indexing documents
  stem_langs.each do |lang|
    filespath = Setting.plugin_redmine_dmsf['dmsf_storage_directory'] || File.join(REDMINE_ROOT, FILES)
    unless File.directory?(filespath)
      warn "'#{filespath}' doesn't exist."
      exit 1
    end
    databasepath = File.join(db_root_path, lang)
    unless File.directory?(databasepath)
      log "#{databasepath} does not exist, creating ...", verbose
      FileUtils.mkdir_p databasepath
    end
    cmd = +"#{OMINDEX} -s #{lang} --db #{databasepath} #{filespath} --url / --depth-limit=0"
    cmd << ' -v' if verbose
    cmd << ' --retry-failed' if retry_failed
    cmd << ' -p' if no_delete
    cmd << " -m #{max_size}" if max_size.present?
    cmd << ' --overwrite' if overwrite
    log cmd, verbose
    system_or_raise cmd, verbose
  end
  log 'Redmine DMS documents indexed', verbose
rescue LoadError => e
  warn e.message
  exit 1
end

exit 0
