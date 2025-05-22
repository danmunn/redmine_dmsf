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

# Add columns
class TrashBin < ActiveRecord::Migration[4.2]
  def up
    # DMSF - project's root folder notification
    change_table :dmsf_folders, bulk: true do |t|
      t.column :deleted, :boolean, default: false, null: false
      t.column :deleted_by_user_id, :integer
    end
    DmsfFolder.reset_column_information
    DmsfFolder.update_all deleted: false
  end

  def down
    change_table :dmsf_folders, bulk: true do |t|
      t.remove :deleted
      t.remove :deleted_by_user_id
    end
  end
end
