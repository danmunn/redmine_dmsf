# == Schema Information
#
# Table name: dmsf_workflow_step_actions
#
#  id                 :integer          not null, primary key
#  workflow_step_id   :integer          not null
#  action             :boolean          not null
#  note               :text             not null
#

class DmsfWorkflowStepAction < ActiveRecord::Base

end