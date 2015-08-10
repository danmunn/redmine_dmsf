# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
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
  belongs_to :dmsf_workflow
  has_many :dmsf_workflow_step_assignments, :dependent => :destroy
  validates :dmsf_workflow_id, :presence => true
  validates :step, :presence => true
  validates :user_id, :presence => true
  validates :operator, :presence => true
  validates_uniqueness_of :user_id, :scope => [:dmsf_workflow_id, :step]    
  
  OPERATOR_OR  = 0
  OPERATOR_AND = 1

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
  
  def is_finished?(dmsf_file_revision_id)
    self.dmsf_workflow_step_assignments.each do |assignment|
      if assignment.dmsf_file_revision_id == dmsf_file_revision_id
        if assignment.dmsf_workflow_step_actions.empty?            
          return false
        end          
        assignment.dmsf_workflow_step_actions.each do |act|
          return false unless act.is_finished?              
        end
      end               
    end      
  end
  
  def copy_to(workflow)
    new_step = self.dup
    new_step.dmsf_workflow_id = workflow.id
    new_step.save
    return new_step
  end
end