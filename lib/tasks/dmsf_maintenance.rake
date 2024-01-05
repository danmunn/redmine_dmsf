# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

desc <<~END_DESC
  DMSF maintenance task
    * Remove all files with no database record from the document directory
    * Remove all links project_id = -1 (added links to an issue which hasn't been created)
    * Report all documents without a corresponding file in the file system (dry_run only)

  Available options:
    *dry_run - No physical deletion but to list of all unused files only

  Example:
    rake redmine:dmsf_maintenance RAILS_ENV="production"
    rake redmine:dmsf_maintenance dry_run=1 RAILS_ENV="production"
END_DESC

namespace :redmine do
  task dmsf_maintenance: :environment do
    m = DmsfMaintenance.new
    begin
      $stdout.puts "\n"
      Dir.chdir DmsfFile.storage_path.to_s
      $stdout.puts "Files...\n"
      m.files
      $stdout.puts "Documents...\n"
      m.documents
      if m.dry_run
        m.result
      else
        m.clean
      end
    rescue StandardError => e
      warn e.message
    end
  end
end

# Maintenance
class DmsfMaintenance
  include ActionView::Helpers::NumberHelper

  attr_accessor :dry_run

  def initialize
    @dry_run = ENV.fetch('dry_run', nil)
    @files_to_delete = []
    @documents_to_delete = []
  end

  def files
    Dir.glob('**/*').each do |f|
      check_file(f) unless Dir.exist?(f)
    end
  end

  def documents
    DmsfFile.find_each do |f|
      r = f.last_revision
      if r.nil? || !File.exist?(r.disk_file)
        @documents_to_delete << f
        $stdout.puts "\t#{r.disk_file}\n" if r
      end
    end
  end

  def result
    # Files
    size = 0
    @files_to_delete.each { |f| size += File.size(f) }
    $stdout.puts "\n#{@files_to_delete.count} files haven't got a corresponding revision and can be deleted."
    $stdout.puts "#{number_to_human_size(size)} can be released.\n\n"
    # Links
    size = DmsfLink.where(project_id: -1).count
    $stdout.puts "#{size} links can be deleted.\n\n"
    # Documents
    $stdout.puts "#{@documents_to_delete.size} corrupted documents.\n\n"
  end

  def clean
    # Files
    size = 0
    @files_to_delete.each do |f|
      size += File.size(f)
      File.delete f
    end
    $stdout.puts "\n#{@files_to_delete.count} files hadn't got a coresponding revision and have been be deleted."
    $stdout.puts "#{number_to_human_size(size)} has been released\n\n"
    # Links
    size = DmsfLink.where(project_id: -1).count
    DmsfLink.where(project_id: -1).delete_all
    $stdout.puts "#{size} links have been deleted.\n\n"
  end

  private

  def check_file(file)
    name = Pathname.new(file).basename.to_s
    if name.match?(/^\d+_\d+_.*/)
      n = DmsfFileRevision.where(disk_filename: name).count
      unless n.positive?
        @files_to_delete << file
        $stdout.puts "\t#{file}\t#{number_to_human_size(File.size(file))}"
      end
    else
      warn "\t#{file} doesn't seem to be a DMSF file!"
    end
  end
end
