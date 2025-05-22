# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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

# Initial schema
class CreateHierarchy < ActiveRecord::Migration[4.2]
  def change
    create_table :dmsf_folders do |t|
      t.references :project, null: false
      t.references :dmsf_folder
      t.string :name, null: false
      t.text :description
      t.boolean :notification, default: false, null: false
      t.references :user, null: false
      t.timestamps
    end
    create_table :dmsf_files do |t|
      t.references :project, null: false
      # This two fileds are copy from last revision due to simpler search
      t.references :dmsf_folder
      t.string :name, null: false
      t.boolean :notification, default: false, null: false
      t.boolean :deleted, default: false, null: false
      t.integer :deleted_by_user_id
      t.timestamps
    end
    create_table :dmsf_file_revisions do |t|
      t.references :dmsf_file, null: false
      t.integer :source_dmsf_file_revision_id
      t.string :name, null: false
      t.references :dmsf_folder
      t.string :disk_filename, null: false
      t.integer :size
      t.string :mime_type
      t.string :title
      t.text :description
      t.integer :workflow
      t.integer :major_version, null: false
      t.integer :minor_version, null: false
      t.text :comment
      t.boolean :deleted, default: false, null: false
      t.integer :deleted_by_user_id
      t.references :user, null: false
      t.timestamps
    end
    create_table :dmsf_file_locks do |t|
      t.references :dmsf_file, null: false
      t.boolean :locked, default: false, null: false
      t.references :user, null: false
      t.timestamps
    end
    create_table :dmsf_user_prefs do |t|
      t.references :project, null: false
      t.references :user, null: false
      t.boolean :email_notify, null: false, default: false
      t.timestamps
    end
  end
end
