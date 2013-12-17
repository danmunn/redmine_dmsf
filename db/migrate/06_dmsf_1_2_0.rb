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

class Dmsf120 < ActiveRecord::Migration
  
  class DmsfFileRevision < ActiveRecord::Base
    belongs_to :file, :class_name => 'DmsfFile', :foreign_key => 'dmsf_file_id'
    belongs_to :source_revision, :class_name => 'DmsfFileRevision', :foreign_key => 'source_dmsf_file_revision_id'
    belongs_to :user
    belongs_to :folder, :class_name => 'DmsfFolder', :foreign_key => 'dmsf_folder_id'
    belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'
    belongs_to :project
  end
  
  def self.up
    add_column :dmsf_file_revisions, :project_id, :integer, :null => true
    
    DmsfFileRevision.find_each do |revision|
      revision.project = revision.file.project
      revision.save
    end
    
    change_column :dmsf_file_revisions, :project_id, :integer, :null => false
  end

  def self.down
    remove_column :dmsf_file_revisions, :project_id 
  end

end
