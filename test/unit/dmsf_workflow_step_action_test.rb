require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowStepActionTest < Test::UnitTest

  fixtures :dmsf_workflow_steps, :dmsf_workflow_step_actions
  
  def setup
    @wfsac1 = Dmsf::WorkflowStepAction.find(1)
    @wfsac2 = Dmsf::WorkflowStepAction.find(2)
    @wfsac3 = Dmsf::WorkflowStepAction.find(3)
  end
  
  def test_truth
    assert_kind_of Dmsf::WorkflowStepAction, @wfsac1
    assert_kind_of Dmsf::WorkflowStepAction, @wfsac2
    assert_kind_of Dmsf::WorkflowStepAction, @wfsac3
  end
  
  def test_create
    wfsac = Dmsf::WorkflowStepAction.new(
      :workflow_step_assignment_id => 1,
      :action => 1,
      :note => 'Approvement')
    assert wfsac.save
    wfsac.reload
    assert wfsac.created_at
  end
  
  def test_update    
    @wfsac1.workflow_step_assignment_id = 2    
    @wfsac1.action = 2
    @wfsac1.note = 'Rejection'
    
    assert @wfsac1.save
    @wfsac1.reload
    
    assert_equal 2, @wfsac1.workflow_step_assignment_id    
    assert_equal 2, @wfsac1.action
    assert_equal 'Rejection', @wfsac1.note
  end
  
  def test_validate_workflow_step_assignment_id_presence
    @wfsac1.workflow_step_assignment_id = nil
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count        
  end
  
  def test_validate_action_presence
    @wfsac1.action = nil
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count        
  end
  
  def test_destroy  
    @wfsac1.destroy
    assert_nil Dmsf::WorkflowStepAction.find_by_id(1)    
  end
end
