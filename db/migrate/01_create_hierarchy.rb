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

class CreateHierarchy < ActiveRecord::Migration
  def self.up
    create_table :dmsf_folders do |t|
      t.references :project, :null => false
      t.references :dmsf_folder
      
      t.string :name, :null => false
      t.text :description
      
      t.boolean :notification, :default => false, :null => false
      
      t.references :user, :null => false
      t.timestamps :null => false
    end
    
    create_table :dmsf_files do |t|
      t.references :project, :null => false
      
      # This two fileds are copy from last revision due to simpler search
      t.references :dmsf_folder
      t.string :name, :null => false

      t.boolean :notification, :default => false, :null => false
      
      t.boolean :deleted, :default => false, :null => false
      t.integer :deleted_by_user_id
      
      t.timestamps  :null => false
    end
    
    create_table :dmsf_file_revisions do |t|
      t.references :dmsf_file, :null => false
      t.integer :source_dmsf_file_revision_id
      
      t.string :name, :null => false
      t.references :dmsf_folder
      
      t.string :disk_filename, :null => false
      t.integer :size
      t.string :mime_type
      
      t.string :title
      t.text :description
      t.integer :workflow
      t.integer :major_version, :null => false
      t.integer :minor_version, :null => false
      t.text :comment
      
      t.boolean :deleted, :default => false, :null => false
      t.integer :deleted_by_user_id
      
      t.references :user, :null => false
      t.timestamps  :null => false
    end
    
    create_table :dmsf_file_locks do |t|
      t.references :dmsf_file, :null => false
      t.boolean :locked, :default => false, :null => false
      t.references :user, :null => false
      t.timestamps  :null => false
    end
    
    create_table :dmsf_user_prefs do |t|
      t.references :project, :null => false
      t.references :user, :null => false
      
      t.boolean :email_notify
      
      t.timestamps  :null => false
    end
    
  end

  def self.down
    drop_table :dmsf_file_revisions
    drop_table :dmsf_files
    drop_table :dmsf_folders
    drop_table :dmsf_file_locks
    drop_table :dmsf_user_prefs
  end
end
