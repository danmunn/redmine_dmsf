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
class CreateDmsfWorkflowStepActions < ActiveRecord::Migration[4.2]
  def change
    create_table :dmsf_workflow_step_actions do |t|
      t.references :dmsf_workflow_step_assignment, null: false
      t.integer :action, null: false
      t.text :note
      t.datetime :created_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.integer :author_id, null: false
    end
    add_index :dmsf_workflow_step_actions,
              :dmsf_workflow_step_assignment_id,
              # The default index name exceeds the index name limit
              name: :idx_dmsf_wfstepact_on_wfstepassign_id
  end
end
