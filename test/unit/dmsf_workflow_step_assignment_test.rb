require File.expand_path('../../test_helper', __FILE__)

class WorkflowStepAssignmentTest < Test::UnitTest
  
  fixtures :users, :dmsf_entities, :dmsf_workflow_steps, :dmsf_workflow_step_assignments
  
  def setup
    @wfsa1 = Dmsf::WorkflowStepAssignment.find(1)
  end
  
  def test_truth
    assert_kind_of Dmsf::WorkflowStepAssignment, @wfsa1
  end
  
  def test_create
    wfsa = Dmsf::WorkflowStepAssignment.new(      
      :workflow_step_id => 2,
      :user_id => 2,
      :entity_id => 2)   
    assert wfsa.save
  end
  
  def test_update    
    @wfsa1.workflow_step_id = 2    
    @wfsa1.user_id = 2
    @wfsa1.entity_id = 2
    
    assert @wfsa1.save
    @wfsa1.reload
    
    assert_equal 2, @wfsa1.workflow_step_id    
    assert_equal 2, @wfsa1.user_id
    assert_equal 2, @wfsa1.entity_id
  end
  
  def test_validate_workflow_step_id_presence
    @wfsa1.workflow_step_id = nil
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count        
  end
  
  def test_validate_workflow_entity_id_presence
    @wfsa1.entity_id = nil
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count        
  end
  
  def test_destroy  
    @wfsa1.destroy
    assert_nil Dmsf::WorkflowStepAssignment.find_by_id(1)
    assert_nil Dmsf::WorkflowStepAction.find_by_id(1)
  end
end
