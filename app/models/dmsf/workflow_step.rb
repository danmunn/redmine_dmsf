# == Schema Information
#
# Table name: dmsf_workflow_step
#
#  id                 :integer          not null, primary key
#  workflow_id        :integer          not mull
#  step               :boolean          not null
#  user_id            :integer          not null
#  operator           :boolean          not null
#
module Dmsf
  class WorkflowStep < Dmsf::ActiveRecordBase
    belongs_to :workflow
    
    has_many :workflow_step_assignments, :dependent => :destroy
        
    validates :workflow_id, :presence => true
    validates :step, :presence => true
    validates :user_id, :presence => true
    validates :operator, :presence => true
    validates_uniqueness_of :user_id, :scope => [:workflow_id, :step]
    
    def soperator
      operator == 1 ? l(:dmsf_and) : l(:dmsf_or)
    end
    
    def user
      User.find(user_id)
    end
  end
end