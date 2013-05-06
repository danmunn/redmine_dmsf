# == Schema Information
#
# Table name: dmsf_workflow
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  project_id         :integer          not null
#

module Dmsf
  class Workflow < Dmsf::ActiveRecordBase
    belongs_to :project

    has_many :workflow_steps, :dependent => :destroy

    validates_uniqueness_of :name
    validates :name, :presence => true
    validates_length_of :name, :maximum => 255

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
      workflow_steps.each do |s|
        if s.step == step
          wa << s
        end
      end
      wa.sort_by { |obj| -obj.operator }
    end
    
    def steps         
      ws = Array.new
      workflow_steps.each do |s|
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
            workflow_steps.each do |ws|              
              if ws.step < step                
                ws.update_attribute('step', ws.step + 1)
              elsif ws.step == step                
                ws.update_attribute('step', 1)
              end            
            end          
          end
        when 'higher'
          unless step == 1            
            workflow_steps.each do |ws|
              if ws.step == step - 1                                
                ws.update_attribute('step', step)
              elsif ws.step == step                
                ws.update_attribute('step', step - 1)
              end            
            end          
          end
        when 'lower'
          unless step == steps.count            
            workflow_steps.each do |ws|                            
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
            workflow_steps.each do |ws|                            
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
  end
end