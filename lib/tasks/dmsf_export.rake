# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17   Karel Picman <karel.picman@kontron.com>
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
DMSF export task
  * Simply export a folder as CSV

Available options:
  *folder_id - A folder ID

Example:
  rake redmine:dmsf_export folder_id=22682 RAILS_ENV="production"
  rake redmine:dmsf_export folder_id=22682 RAILS_ENV="production" 1>data.csv
END_DESC
  
namespace :redmine do
  task :dmsf_export => :environment do
    begin
      m = DmsfExport.new
      m.export
    rescue Exception => e
      STDERR.puts e.message
    end
  end
end

class DmsfExport

  def initialize
    @folder = DmsfFolder.find ENV['folder_id']
  end 
  
  def export
      puts "\"Title\";\"Size\";\"Modified\";\"Ver.\";\"Workflow\";\"Author\";\"Doc ID\";\"Active\nDoc\nrevision\";\"URL\"\n"
      @folder.dmsf_files.visible.order(:name).each do |f|
        puts f.to_csv
        puts "\n"
      end
  end

end