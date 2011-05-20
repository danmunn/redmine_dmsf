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

require "tmpdir"

module DmsfHelper

  def self.temp_dir
    Dir.tmpdir
  end

  def self.temp_filename(filename)
    filename = sanitize_filename(filename)
    timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
    while File.exist?(File.join(temp_dir, "#{timestamp}_#{filename}"))
      timestamp.succ!
    end
    "#{timestamp}_#{filename}"
  end
  
  def self.sanitize_filename(filename)
    # get only the filename, not the whole path
    just_filename = File.basename(filename.gsub('\\\\', '/'))

    # Finally, replace all non alphanumeric, hyphens or periods with underscore
    just_filename.gsub(/[^\w\.\-]/,'_') 
  end
  
  def self.filetype_css(filename)
    extension = File.extname(filename)
    extension = extension[1, extension.length-1]
    if File.exists?("#{File.dirname(__FILE__)}/../../assets/images/filetypes/#{extension}.png")
      return "filetype-#{extension}";
    else
      return Redmine::MimeType.css_class_of(filename)
    end
  end
  
  def self.directory_tree(project)
    tree = [["Documents", nil]]
    DmsfFolder.project_root_folders(project).each do |folder|
      tree.push(["...#{folder.name}", folder.id])
      directory_subtree(tree, folder, 2)
    end
    return tree
  end
  
  private
  
  def self.directory_subtree(tree, folder, level)
    folder.subfolders.each do |subfolder|
      tree.push(["#{"..." * level}#{subfolder.name}", subfolder.id])
      directory_subtree(tree, subfolder, level + 1)
    end
  end
  
end
