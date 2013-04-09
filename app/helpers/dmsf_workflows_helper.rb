module DmsfWorkflowsHelper
  def dmsf_workflow_settings_tabs
    [{:name => 'general', :partial => 'dmsf_workflows/general', :label => :label_general},
     {:name => 'steps', :partial => 'dmsf_workflows/steps', :label => :label_dmsf_workflow_step_plural}]
  end
end
