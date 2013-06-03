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

class DmsfWorkflowStepAction < ActiveRecord::Base
 
  belongs_to :dmsf_workflow_step_assignment    

  validates :dmsf_workflow_step_assignment_id, :presence => true
  validates :action, :presence => true
  validates :note, :presence => true, :unless => lambda { self.action == DmsfWorkflowStepAction::ACTION_APPROVE }
  validates :author_id, :presence => true
  
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
   
end