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
require 'iconv'

class DmsfZip

  attr_reader :files

  def initialize()
    @zip = Tempfile.new(["dmsf_zip",".zip"])
    @zip.chmod(0644)
    @zip_file = Zip::ZipOutputStream.new(@zip.path)
    @files = []
  end

  def finish
    @zip_file.close unless @zip_file.nil?
    @zip.path unless @zip.nil?
  end

  def close
    @zip_file.close unless @zip_file.nil?
    @zip.close unless @zip.nil?
  end

  def add_file(file, root_path = nil)
    string_path = file.folder.nil? ? "" : file.folder.dmsf_path_str + "/"
    string_path = string_path[(root_path.length + 1) .. string_path.length] if root_path
    string_path += file.name
    #TODO: somewhat ugly conversion problems handling bellow
    begin
      string_path = Iconv.conv(Setting.plugin_redmine_dmsf["dmsf_zip_encoding"], "utf-8", string_path)
    rescue
    end
    @zip_file.put_next_entry(string_path)
    File.open(file.last_revision.disk_file, "rb") do |f|
      buffer = ""
      while (buffer = f.read(8192))
        @zip_file.write(buffer)
      end
    end
    @files << file
  end

  def add_folder(folder, root_path = nil)
    string_path = folder.dmsf_path_str + "/"
    string_path = string_path[(root_path.length + 1) .. string_path.length] if root_path
    #TODO: somewhat ugly conversion problems handling bellow
    begin
      string_path = Iconv.conv(Setting.plugin_redmine_dmsf["dmsf_zip_encoding"], "utf-8", string_path)
    rescue
    end
    @zip_file.put_next_entry(string_path)
    folder.subfolders.visible.each { |subfolder| self.add_folder(subfolder, root_path) }
    folder.files.visible.each { |file| self.add_file(file, root_path) }
  end

end
