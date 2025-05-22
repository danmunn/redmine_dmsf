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

# Create table
class CreateDmsfLinks < ActiveRecord::Migration[4.2]
  def change
    create_table :dmsf_links do |t|
      t.integer :target_project_id, null: false
      t.integer :target_id, null: false
      t.string :target_type, limit: 10, null: false
      t.string :name, null: false
      t.references :project, null: false
      t.references :dmsf_folder
      t.boolean :deleted, default: false, null: false
      t.integer :deleted_by_user_id
      t.timestamps null: false
    end
    add_index :dmsf_links, :project_id
  end
end
