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

  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, :presence => true
  validates_length_of :name, :maximum => 255
  
  STATE_NONE = nil
  STATE_ASSIGNED = 3
  STATE_WAITING_FOR_APPROVAL = 1
  STATE_APPROVED = 2
  STATE_REJECTED = 4
  
  def participiants
    users = Array.new
    self.dmsf_workflow_steps.each do |step|
      users << step.user unless users.include? step.user
    end
    users
  end

  def self.workflows(project)
    project ? where(:project_id => project) : where('project_id IS NULL')      
  end

  def project          
    Project.find_by_id(project_id) if project_id
  end

  def to_s
    name
  end   

  def reorder_steps(step, move_to)
    DmsfWorkflow.transaction do
      case move_to
        when 'highest'          
          unless step == 1            
            dmsf_workflow_steps.each do |ws|              
              if ws.step < step
               return false unless ws.update_attribute('step', ws.step + 1)               
              elsif ws.step == step                
                return false unless ws.update_attribute('step', 1)
              end            
            end          
          end
        when 'higher'
          unless step == 1            
            dmsf_workflow_steps.each do |ws|
              if ws.step == step - 1                                
                return false unless ws.update_attribute('step', step)
              elsif ws.step == step                
                return false unless ws.update_attribute('step', step - 1)
              end            
            end          
          end
        when 'lower'
          unless step == dmsf_workflow_steps.collect{|s| s.step}.uniq.count            
            dmsf_workflow_steps.each do |ws|
              if ws.step == step + 1                
                return false unless ws.update_attribute('step', step)                
              elsif ws.step == step                
                return false unless ws.update_attribute('step', step + 1)                
              end              
            end            
          end
        when 'lowest'                   
          size = dmsf_workflow_steps.collect{|s| s.step}.uniq.count
          unless step == size
            dmsf_workflow_steps.each do |ws|                            
              if ws.step > step                
                return false unless ws.update_attribute('step', ws.step - 1)
              elsif ws.step == step                
                return false unless ws.update_attribute('step', size)
              end
            end            
          end                            
      end     
    end
    return reload    
  end
  
  def delegates(q, dmsf_workflow_step_assignment_id, dmsf_file_revision_id)        
    if dmsf_workflow_step_assignment_id && dmsf_file_revision_id
      sql = [
        'id NOT IN (SELECT a.user_id FROM dmsf_workflow_step_assignments a WHERE id = ?) AND id IN (SELECT m.user_id FROM members m JOIN dmsf_files f ON f.project_id = m.project_id JOIN dmsf_file_revisions r ON r.dmsf_file_id = f.id WHERE r.id = ?)', 
        dmsf_workflow_step_assignment_id, 
        dmsf_file_revision_id]
    elsif project
      sql = ['id IN (SELECT user_id FROM members WHERE project_id = ?)', project.id]
    else
      sql = '1=1'
    end
    
    if q.present?
      User.active.sorted.where(sql).like(q)
    else
      User.active.sorted.where(sql)
    end    
  end
  
  def next_assignments(dmsf_file_revision_id)    
    results = Array.new  
    nsteps = self.dmsf_workflow_steps.collect{|s| s.step}.uniq
    nsteps.each do |i|
      step_is_finished = false      
      steps = self.dmsf_workflow_steps.collect{|s| s.step == i ? s : nil}.compact
      steps.each do |step|
        step.dmsf_workflow_step_assignments.each do |assignment|
          if assignment.dmsf_file_revision_id == dmsf_file_revision_id
            assignment.dmsf_workflow_step_actions.each do |action|
              case action.action
              when DmsfWorkflowStepAction::ACTION_APPROVE
                step_is_finished = true
                # Try to find another unfinished AND step  
                exists = false
                stps = self.dmsf_workflow_steps.collect{|s| (s.step == i && s.operator == DmsfWorkflowStep::OPERATOR_AND) ? s : nil}.compact
                stps.each do |s|
                  s.dmsf_workflow_step_assignments.each do |a|
                    exists = a.add?(dmsf_file_revision_id)                    
                    break if exists                    
                  end
                end  
                step_is_finished = false if exists
                break
              when DmsfWorkflowStepAction::ACTION_REJECT
                return Array.new              
              end
            end
          end
          break if step_is_finished
        end 
        if step_is_finished
          break        
        else
          steps.each do |step|
            step.dmsf_workflow_step_assignments.each do |assignment|              
              results << assignment if assignment.add?(dmsf_file_revision_id)              
            end
          end
          return results
        end
      end
    end
    results
  end
  
  def self.assignments_to_users_str(assignments)
    str = ''
    if assignments      
      assignments.each_with_index do |assignment, index|        
        if index > 0
          str << ', '
        end
        str << assignment.user.name        
      end
    end
    str    
  end
   
  def assign(dmsf_file_revision_id)
    dmsf_workflow_steps.each do |ws|
      ws.assign(dmsf_file_revision_id)
    end
  end
  
  def try_finish(revision, action, user_id)         
    case action.action
      when DmsfWorkflowStepAction::ACTION_APPROVE   
        assignments = self.next_assignments revision.id
        return false unless assignments.empty?
        revision.update_attribute(:workflow, DmsfWorkflow::STATE_APPROVED)
        return true
      when DmsfWorkflowStepAction::ACTION_REJECT
        revision.update_attribute(:workflow, DmsfWorkflow::STATE_REJECTED)
        return true
      when DmsfWorkflowStepAction::ACTION_DELEGATE        
        self.dmsf_workflow_steps.each do |step|
          step.dmsf_workflow_step_assignments.each do |assignment|
            if assignment.id == action.dmsf_workflow_step_assignment_id
              assignment.update_attribute(:user_id, user_id)
              return false
            end
          end
        end
    end
    return false
  end  
end