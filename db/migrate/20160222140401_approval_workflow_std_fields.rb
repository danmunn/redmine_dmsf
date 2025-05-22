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

# Add columns
class ApprovalWorkflowStdFields < ActiveRecord::Migration[4.2]
  def up
    change_table :dmsf_workflows, bulk: true do |t|
      t.column :updated_on, :timestamp
      t.column :created_on, :datetime
      t.column :author_id, :integer
    end
    DmsfWorkflow.reset_column_information
    # Set updated_on
    DmsfWorkflow.find_each(&:touch)
    # Set created_on and author_id
    admin_ids = User.active.where(admin: true).limit(1).ids
    DmsfWorkflow.update_all ['created_on = updated_on, author_id = ?', admin_ids.first]
  end

  def down
    change_table :dmsf_workflows, bulk: true do |t|
      t.remove :updated_on
      t.remove :created_on
      t.remove :author_id
    end
  end
end
