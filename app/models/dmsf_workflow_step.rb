# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013   Karel Picman <karel.picman@kontron.com>
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

class DmsfWorkflowStep < ActiveRecord::Base
  belongs_to :workflow

  has_many :dmsf_workflow_step_assignments, :dependent => :destroy

  validates :dmsf_workflow_id, :presence => true
  validates :step, :presence => true
  validates :user_id, :presence => true
  validates :operator, :presence => true
  validates_uniqueness_of :user_id, :scope => [:dmsf_workflow_id, :step]

  def soperator
    operator == 1 ? l(:dmsf_and) : l(:dmsf_or)
  end

  def user
    User.find(user_id)
  end
  
  def assign(dmsf_file_revision_id)
    step_assignment = DmsfWorkflowStepAssignment.new(
      :dmsf_workflow_step_id => id,
      :user_id => user_id,
      :dmsf_file_revision_id => dmsf_file_revision_id)
    step_assignment.save
  end
  
  def finished?(dmsf_file_revision_id)            
    res = result(dmsf_file_revision_id)
    res == DmsfWorkflow::STATE_APPROVED || res == DmsfWorkflow::STATE_REJECTED
  end
  
  def result(dmsf_file_revision_id)        
    assignments = DmsfWorkflowStepAssignment.where(
      :dmsf_workflow_step_id => self.id, :dmsf_file_revision_id => dmsf_file_revision_id).all
    assignments.each do |assignment|
      actions = DmsfWorkflowStepAction.where(
        :dmsf_workflow_step_assignment_id => assignment.id).all
      if actions.empty?
        return
      end
      actions.each do |action|
        if DmsfWorkflowStepAction.is_finished?(action.action)
          case action.action
            when DmsfWorkflowStepAction::ACTION_APPROVE
              return DmsfWorkflow::STATE_APPROVED
            when DmsfWorkflowStepAction::ACTION_REJECT
              return DmsfWorkflow::STATE_REJECTED
            else
              return
          end
        end
      end
    end
  end
  
  def get_free_assignment(dmsf_file_revision_id, user)  
    assignment = DmsfWorkflowStepAssignment.where(
      :dmsf_workflow_step_id => self.id, 
      :dmsf_file_revision_id => dmsf_file_revision_id,
      :user_id => user.id).first
   if assignment
     actions = DmsfWorkflowStepAction.where(
        :dmsf_workflow_step_assignment_id => assignment.id).all
     actions.each do |action|
       if action && action.is_finished?
         return
       end
     end
     return assignment.id       
   end
  end
  
end