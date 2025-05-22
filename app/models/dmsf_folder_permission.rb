# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

# Folder permission
class DmsfFolderPermission < ApplicationRecord
  belongs_to :dmsf_folder

  scope :users, -> { where(object_type: User.model_name.to_s) }
  scope :roles, -> { where(object_type: Role.model_name.to_s) }

  def copy_to(folder)
    permission = DmsfFolderPermission.new
    permission.dmsf_folder_id = folder.id
    permission.object_id = object_id
    permission.object_type = object_type
    permission.save!
    permission
  end
end
