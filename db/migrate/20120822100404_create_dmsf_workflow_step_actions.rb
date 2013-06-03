# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013 Karel Picman <karel.picman@kontron.com>
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

class CreateDmsfWorkflowStepActions < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflow_step_actions do |t|
      t.references :dmsf_workflow_step_assignment, :null => false
      t.integer :action, :null => false
      t.text :note      
      t.timestamp :created_at
      t.integer :author_id, :null => false
    end
    add_index :dmsf_workflow_step_actions, 
      :dmsf_workflow_step_assignment_id,
      # The default index name exceeds the index name limit
      {:name => 'index_dmsf_workflow_step_actions_on_workflow_step_assignment_id'}
  end
  def self.down
    drop_table :dmsf_workflow_step_actions
  end
end
