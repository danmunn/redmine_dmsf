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
      if project
        where(:project_id => project)
      else
        where('project_id IS NULL')
      end
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
  end
end