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

class DmsfWorkflowStepAction < ActiveRecord::Base
 
  belongs_to :dmsf_workflow_step_assignment    

  validates :dmsf_workflow_step_assignment_id, :presence => true
  validates :action, :presence => true
  validates :note, :presence => true, :unless => lambda { self.action == DmsfWorkflowStepAction::ACTION_APPROVE }
  validates :author_id, :presence => true
  validates_uniqueness_of :dmsf_workflow_step_assignment_id, :scope => [:action], :unless => lambda {self.action == DmsfWorkflowStepAction::ACTION_DELEGATE}  
  
  attr_accessible :dmsf_workflow_step_assignment_id, :action, :note
  
  ACTION_APPROVE = 1
  ACTION_REJECT = 2
  ACTION_DELEGATE = 3
  ACTION_ASSIGN = 4
  ACTION_START = 5
  
  def initialize(*args)
    super
    self.author_id = User.current.id if User.current    
  end
    
  def self.is_finished?(action)
    action == DmsfWorkflowStepAction::ACTION_APPROVE ||
      action == DmsfWorkflowStepAction::ACTION_REJECT
  end
  
  def is_finished?
    DmsfWorkflowStepAction.is_finished? self.action
  end
  
  def self.action_str(action)
    if action
      case action.to_i
        when ACTION_APPROVE
          l(:title_approval)
        when ACTION_REJECT
          l(:title_rejection)
        when ACTION_DELEGATE
          l(:title_delegation)
        when ACTION_ASSIGN
          l(:title_assignment)
        when ACTION_START
          l(:title_start)
      end
    end
  end
  
  def self.action_type_str(action)
    if action
      case action.to_i
        when ACTION_APPROVE
          'approval'
        when ACTION_REJECT
          'rejection'
        when ACTION_DELEGATE
          'delegation'
        when ACTION_ASSIGN
          'assignment'
        when ACTION_START
          'start'
      end
    end
  end
  
  def self.workflow_str(action)
    if action
      case action.to_i        
        when ACTION_REJECT
          l(:title_rejected)       
        when ACTION_ASSIGN
          l(:title_assigned)
        when ACTION_START, ACTION_DELEGATE, ACTION_APPROVE
          l(:title_waiting_for_approval)
        else
          l(:title_none)
      end
    end
  end
   
end