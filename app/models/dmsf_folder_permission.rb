# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@konton.com>
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

class DmsfFolderPermission < ActiveRecord::Base
  unloadable

  belongs_to :dmsf_folder

  scope :users, -> { where(:object_type => User.model_name.to_s) }
  scope :roles, -> { where(:object_type => Role.model_name.to_s) }

  def copy_to(folder)
    permission = DmsfFolderPermission.new
    permission.dmsf_folder_id = folder.id
    permission.object_id = self.object_id
    permission.object_type = self.object_type
    permission.save
    permission
  end

end
