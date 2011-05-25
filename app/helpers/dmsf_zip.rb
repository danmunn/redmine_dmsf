# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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

require 'zip/zip'
require 'zip/zipfilesystem'

class DmsfZip
  
  attr_reader :file_count
  
  def initialize()
    @zip = Tempfile.new(["dmsf_zip",".zip"])
    @zip_file = Zip::ZipOutputStream.new(@zip.path)
    @file_count = 0
  end
  
  def finish
    @zip_file.close unless @zip_file.nil?
    @zip.path unless @zip.nil?
  end
  
  def close
    @zip_file.close unless @zip_file.nil?
    @zip.close unless @zip.nil?
  end
  
  def add_file(file)
    string_path = file.folder.nil? ? "" : file.folder.dmsf_path_str + "/"
    string_path += file.name
    @zip_file.put_next_entry(string_path)
    File.open(file.last_revision.disk_file, "rb") do |f| 
      buffer = ""
      while (buffer = f.read(8192))
        @zip_file.write(buffer)
      end
    end
    @file_count += 1
  end
  
  def add_folder(folder)
    @zip_file.put_next_entry(folder.dmsf_path_str + "/")
    folder.subfolders.each { |subfolder| self.add_folder(subfolder) }
    folder.files.each { |file| self.add_file(file) }
  end
  
end