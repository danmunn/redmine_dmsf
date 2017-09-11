# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-15   Karel Picman <karel.picman@kontron.com>
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

desc <<-END_DESC
DMSF maintenance task
  * Remove all files with no database record from the document directory
  * Remove all links project_id = -1 (added links to an issue which hasn't been created)

Available options:
  *dry_run - No physical deletion but to list of all unused files only

Example:
  rake redmine:dmsf_maintenance RAILS_ENV="production"
  rake redmine:dmsf_maintenance dry_run=1 RAILS_ENV="production"
END_DESC
  
namespace :redmine do
  task :dmsf_maintenance => :environment do    
    m = DmsfMaintenance.new
    begin
      STDERR.puts "\n"
      Dir.chdir(DmsfFile.storage_path)       
      m.files
      if m.dry_run
        m.result
      else
        m.clean
      end             
    rescue Exception => e
      puts e.message
    end
  end
end

class DmsfMaintenance
  
  include ActionView::Helpers::NumberHelper
  
  attr_accessor :dry_run
  
  def initialize
    @dry_run = ENV['dry_run']
    @files_to_delete = Array.new
  end 
  
  def files        
    Dir.glob("**/*").each do |f|      
      unless Dir.exist?(f)
        check_file f
      end      
    end   
  end
  
  def result
    # Files    
    size = 0
    @files_to_delete.each{ |f| size += File.size(f) }    
    puts "\n#{@files_to_delete.count} files havn't got a coresponding revision and can be deleted."
    puts "#{number_to_human_size(size)} can be released.\n\n"
    # Links
    size = DmsfLink.where(:project_id => -1).count
    puts "#{size} links can be deleted.\n\n"
  end
  
  def clean
    # Files    
    size = 0
    @files_to_delete.each do |f|            
      size += File.size(f)
      File.delete f
    end 
    puts "\n#{@files_to_delete.count} files hadn't got a coresponding revision and have been be deleted."
    puts "#{number_to_human_size(size)} has been released\n\n"
    # Links
    size = DmsfLink.where(:project_id => -1).count
    DmsfLink.where(:project_id => -1).delete_all
    puts "#{size} links have been deleted.\n\n"
  end
  
  private
  
  def check_file(file)
    name = Pathname.new(file).basename.to_s
    if name =~ /^\d+_\d+_.*/
      n = DmsfFileRevision.where(:disk_filename => name).count
      unless n > 0
        @files_to_delete << file 
        puts "\t#{file}\t#{number_to_human_size(File.size(file))}"
      end
    else
      STDERR.puts "\t#{file} doesn't seem to be a DMSF file!"
    end
  end

end