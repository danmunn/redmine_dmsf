# == Schema Information
#
# Table name: dmsf_workflow
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  project_id         :integer          not null
#

module Dmsf
  class DmsfWorkflow < ActiveRecord::Base
    belongs_to :project
    
    has_many :dmsf_workflow_steps, :dependent => :destroy    
    
    validates_uniqueness_of :name
    validates :name, :presence => true
    
    def self.workflows(project)
      if project
        where(['project_id = ?', project])
      else
        where('project_id IS NULL')
      end
    end        
  end
end
