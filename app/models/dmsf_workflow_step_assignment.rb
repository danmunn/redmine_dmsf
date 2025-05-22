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

# Workflow step assignment
class DmsfWorkflowStepAssignment < ApplicationRecord
  belongs_to :dmsf_workflow_step
  belongs_to :user
  belongs_to :dmsf_file_revision

  has_many :dmsf_workflow_step_actions, dependent: :destroy

  validates :dmsf_workflow_step_id, uniqueness: { scope: [:dmsf_file_revision_id], case_sensitive: true }

  def add?(dmsf_file_revision_id)
    if dmsf_file_revision_id == self.dmsf_file_revision_id
      add = true
      dmsf_workflow_step_actions.each do |action|
        if action.finished?
          add = false
          break
        end
      end
      return add
    end
    false
  end
end
