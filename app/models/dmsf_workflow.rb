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

class DmsfWorkflow < ActiveRecord::Base 
  has_many :dmsf_workflow_steps, :dependent => :destroy, :order => 'step ASC, operator DESC'

  validates_uniqueness_of :name
  validates :name, :presence => true
  validates_length_of :name, :maximum => 255
  
  STATE_NONE = nil
  STATE_DRAFT = 3
  STATE_WAITING_FOR_APPROVAL = 1
  STATE_APPROVED = 2
  STATE_REJECTED = 4

  def self.workflows(project)
    project ? where(:project_id => project) : where('project_id IS NULL')      
  end

  def project          
    Project.find_by_id(project_id) if project_id
  end

  def to_s
    name
  end  

  def approvals(step)
    wa = Array.new
    dmsf_workflow_steps.each do |s|
      if s.step == step
        wa << s
      end
    end    
    wa
  end

  def steps         
    ws = Array.new
    dmsf_workflow_steps.each do |s|
      unless ws.include? s.step
        ws << s.step
      end
    end    
    ws
  end

  def reorder_steps(step, move_to)      
    case move_to
      when 'highest'          
        unless step == 1            
          dmsf_workflow_steps.each do |ws|              
            if ws.step < step                
              ws.update_attribute('step', ws.step + 1)
            elsif ws.step == step                
              ws.update_attribute('step', 1)
            end            
          end          
        end
      when 'higher'
        unless step == 1            
          dmsf_workflow_steps.each do |ws|
            if ws.step == step - 1                                
              ws.update_attribute('step', step)
            elsif ws.step == step                
              ws.update_attribute('step', step - 1)
            end            
          end          
        end
      when 'lower'
        unless step == steps.count            
          dmsf_workflow_steps.each do |ws|                            
            if ws.step == step + 1                
              ws.update_attribute('step', step)
            elsif ws.step == step                
              ws.update_attribute('step', step + 1)
            end            
          end          
        end
      when 'lowest'                   
        size = steps.count
        unless step == size
          dmsf_workflow_steps.each do |ws|                            
            if ws.step > step                
              ws.update_attribute('step', ws.step - 1)
            elsif ws.step == step                
              ws.update_attribute('step', size)
            end
          end            
        end                            
    end      
  end
  
  def delegates(q, dmsf_workflow_step_assignment_id, dmsf_file_revision_id, project_id)        
    if project_id
      sql = ['id IN (SELECT user_id FROM members WHERE project_id = ?', project_id]
    elsif dmsf_workflow_step_assignment_id && dmsf_file_revision_id
      sql = [
        'id NOT IN (SELECT a.user_id FROM dmsf_workflow_step_assignments a WHERE id = ?) AND id IN (SELECT m.user_id FROM members m JOIN dmsf_file_revisions r ON m.project_id = r.project_id WHERE r.id = ?)', 
        dmsf_workflow_step_assignment_id, 
        dmsf_file_revision_id]
    else
      sql = '1=1'
    end
    
    unless q.nil? || q.empty?
      User.active.sorted.where(sql).like(q)
    else
      User.active.sorted.where(sql)
    end    
  end
  
  def next_assignments(dmsf_file_revision_id)    
    self.dmsf_workflow_steps.each do |step|
      unless step.finished?(dmsf_file_revision_id)        
        return step.next_assignments(dmsf_file_revision_id)
      end
    end 
    return nil
  end
  
  def self.assignments_to_users_str(assignments)
    str = ''
    if assignments      
      assignments.each_with_index do |assignment, index|
        user = User.find_by_id assignment.user_id
        if user
          if index > 0
            str << ', '
          end
          str << user.name
        end
      end
    end
    str    
  end
   
  def assign(dmsf_file_revision_id)
    dmsf_workflow_steps.each do |ws|
      ws.assign(dmsf_file_revision_id)
    end
  end
  
  def try_finish(dmsf_file_revision_id, action, user_id)
    res = nil
    case action.action
      when DmsfWorkflowStepAction::ACTION_APPROVE        
        self.dmsf_workflow_steps.each do |step|
          res = step.result dmsf_file_revision_id
          unless step.finished? dmsf_file_revision_id
            return
          end
        end
      when DmsfWorkflowStepAction::ACTION_REJECT
        res = DmsfWorkflow::STATE_REJECTED
      when DmsfWorkflowStepAction::ACTION_DELEGATE
        assignment = DmsfWorkflowStepAssignment.find_by_id(action.dmsf_workflow_step_assignment_id)
        assignment.update_attribute(:user_id, user_id) if assignment
    end
    
    if res
      revision = DmsfFileRevision.find_by_id dmsf_file_revision_id     
      revision.update_attribute(:workflow, res) if revision
    end
  end
  
end