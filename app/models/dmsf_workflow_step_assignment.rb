# == Schema Information
#
# Table name: dmsf_workflow_step_assignments
#
#  id                     :integer          not null, primary key
#  dmsf_workflow_step_id  :integer          not null
#  dmsf_revision_id       :integer          not null
#

class DmsfWorkflowStepAssignment < ActiveRecord::Base
  belongs_to :dmsf_workflow_step

  has_many :dmsf_weokflow_step_actions, :dependent => destroy

  validates :dmsf_workflow_step_id, :presence => true
  validates :dmsf_revision_id, :presence => true
end