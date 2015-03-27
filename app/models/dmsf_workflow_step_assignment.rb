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

class DmsfWorkflowStepAssignment < ActiveRecord::Base
  belongs_to :dmsf_workflow_step
  belongs_to :user
  belongs_to :dmsf_file_revision
  has_many :dmsf_workflow_step_actions, :dependent => :destroy  
  validates :dmsf_workflow_step_id, :dmsf_file_revision_id, :presence => true  
  validates_uniqueness_of :dmsf_workflow_step_id, :scope => [:dmsf_file_revision_id]
  
  attr_accessible :dmsf_workflow_step_id, :user_id, :dmsf_file_revision_id
  
  def add?(dmsf_file_revision_id)
    if self.dmsf_file_revision_id == dmsf_file_revision_id
      add = true
      self.dmsf_workflow_step_actions.each do |action|
        if action.is_finished?              
          add = false
          break
        end
      end
      return add
    end
    false
  end
end