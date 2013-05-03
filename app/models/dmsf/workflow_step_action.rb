# == Schema Information
#
# Table name: dmsf_workflow_step_actions
#
#  id                             :integer          not null, primary key
#  workflow_step_assignment_id    :integer          not null
#  action                         :boolean          not null
#  note                           :text
#  created_at                     :timestamp
#
module Dmsf
  class WorkflowStepAction < Dmsf::ActiveRecordBase
    belongs_to :workflow_step_assignment    

    validates :workflow_step_assignment_id, :presence => true
    validates :action, :presence => true
  end
end