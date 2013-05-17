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
  belongs_to :project

  has_many :dmsf_workflow_steps, :dependent => :destroy

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
    @project = Project.find_by_id(project_id) unless @project
    @project
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
    wa.sort_by { |obj| -obj.operator }
  end

  def steps         
    ws = Array.new
    dmsf_workflow_steps.each do |s|
      unless ws.include? s.step
        ws << s.step
      end
    end
    ws.sort
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

  def delegates
    User.all
  end
  
  def get_free_assignment(user, dmsf_file_revision_id)
    steps = DmsfWorkflowStep.where(:dmsf_workflow_id => self.id).all(:order => 'step ASC')
    steps.each do |step|
      unless step.finished?(dmsf_file_revision_id)        
        return step.get_free_assignment(dmsf_file_revision_id, user)        
      end
    end 
    return nil
  end
  
  def assign(dmsf_file_revision_id)
    dmsf_workflow_steps.each do |ws|
      ws.assign(dmsf_file_revision_id)
    end
  end
  
  def try_finish(dmsf_file_revision_id)
    res = nil
    steps = DmsfWorkflowStep.where(:dmsf_workflow_id => self.id).all
    steps.each do |step|
      res = step.result dmsf_file_revision_id
      unless step.finished? dmsf_file_revision_id
        return
      end
    end
    revision = DmsfFileRevision.find_by_id dmsf_file_revision_id     
    revision.update_attribute(:workflow, res) if revision && res
  end
  
end