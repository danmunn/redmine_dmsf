# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFileContainer < ActiveRecord::Migration
  def up
    remove_index :dmsf_files, :project_id
    rename_column :dmsf_files, :project_id, :container_id
    add_column :dmsf_files, :container_type, :string, :limit => 30, :null => false, :default => 'Project'
    DmsfFile.update_all(:container_type => 'Project')
    add_index :dmsf_files, [:container_id, :container_type]
  end

  def down
    remove_index :dmsf_files, [:container_id, :container_type]
    remove_column :dmsf_files, :container_type
    rename_column :dmsf_files, :container_id, :project_id
    add_index :dmsf_files, :project_id
  end
end
