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

class StatusDeleted < ActiveRecord::Migration
  def self.cast_integer(colname)
    adapter_name = ActiveRecord::Base.connection.adapter_name.downcase
    case adapter_name
    when /postgresql/
      "integer USING CAST(#{colname} AS integer)"
    else
      'integer'
    end
  end
  
  def self.up
    change_column :dmsf_folders, :deleted, :boolean, :default => nil
    change_column :dmsf_files, :deleted, :boolean, :default => nil
    change_column :dmsf_file_revisions, :deleted, :boolean, :default => nil
    change_column :dmsf_links, :deleted, :boolean, :default => nil
    
    change_column :dmsf_folders, :deleted, cast_integer(:deleted), :null => false, :default => DmsfFolder::STATUS_ACTIVE
    change_column :dmsf_files, :deleted, cast_integer(:deleted), :null => false, :default => DmsfFile::STATUS_ACTIVE
    change_column :dmsf_file_revisions, :deleted, cast_integer(:deleted), :null => false, :default => DmsfFileRevision::STATUS_ACTIVE
    change_column :dmsf_links, :deleted, cast_integer(:deleted), :null => false, :default => DmsfLink::STATUS_ACTIVE
  end

  def self.down
  end
end