# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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

class StatusDeleted < ActiveRecord::Migration
  def self.up
    change_column :dmsf_folders, :deleted, :integer, :null => false, :default => DmsfFolder::STATUS_ACTIVE
    change_column :dmsf_files, :deleted, :integer, :null => false, :default => DmsfFile::STATUS_ACTIVE
    change_column :dmsf_file_revisions, :deleted, :integer, :null => false, :default => DmsfFileRevision::STATUS_ACTIVE
    change_column :dmsf_links, :deleted, :integer, :null => false, :default => DmsfLink::STATUS_ACTIVE
  end

  def self.down
    change_column :dmsf_folders, :deleted, :boolean, :null => false, :default => false
    change_column :dmsf_files, :deleted, :boolean, :null => false, :default => false
    change_column :dmsf_file_revisions, :deleted, :boolean, :null => false, :default => false
    change_column :dmsf_links, :deleted, :boolean, :null => false, :default => false
  end
end