# == Schema Information
#
# Table name: dmsf_workflow_step_assignments
#
#  id                     :integer          not null, primary key
#  workflow_step_id  :integer          not null
#  revision_id       :integer          not null
#
module Dmsf
  class WorkflowStepAssignment < ActiveRecord::Base
    belongs_to :workflow_step

    has_many :workflow_step_actions, :dependent => destroy

    validates :workflow_step_id, :presence => true
    validates :revision_id, :presence => true
  end
end