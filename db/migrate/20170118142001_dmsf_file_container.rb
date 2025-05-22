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

# Add column
class DmsfFileContainer < ActiveRecord::Migration[4.2]
  def up
    change_table :dmsf_files, bulk: true do |t|
      t.remove_index :project_id
      t.rename :project_id, :container_id
      t.column :container_type, :string, limit: 30, null: false, default: 'Project'
      t.index %i[container_id container_type]
    end
    DmsfFile.update_all container_type: 'Project'
  end

  def down
    change_table :dmsf_files, bulk: true do |t|
      t.remove_index %i[container_id container_type]
      t.remove :container_type
      t.rename :container_id, :project_id
      t.index :project_id
    end
  end
end
