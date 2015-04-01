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

class Dmsf0901 < ActiveRecord::Migration
  def self.up
    create_table :dmsf_file_revision_accesses do |t|
      t.references :dmsf_file_revision, :null => false
      t.integer :action, :default => 0, :null => false  # 0 ... download, 1 ... email
      t.references :user, :null => false
      t.timestamps  :null => false
    end
  end

  def self.down
    drop_table :dmsf_file_revision_accesses
  end

end
