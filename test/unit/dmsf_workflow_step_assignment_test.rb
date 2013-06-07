require File.expand_path('../../test_helper', __FILE__)

class WorkflowStepAssignmentTest < RedmineDmsf::Test::UnitTest
  
  fixtures :users, :dmsf_file_revisions, :dmsf_workflow_steps, :dmsf_workflow_step_assignments
  
  def setup
    @wfsa1 = DmsfWorkflowStepAssignment.find(1)
  end
  
  def test_truth
    assert_kind_of DmsfWorkflowStepAssignment, @wfsa1
  end
  
  def test_create
    wfsa = DmsfWorkflowStepAssignment.new(      
      :dmsf_workflow_step_id => 2,
      :user_id => 2,
      :dmsf_file_revision_id => 2)   
    assert wfsa.save
  end
  
  def test_update    
    @wfsa1.dmsf_workflow_step_id = 2    
    @wfsa1.user_id = 2
    @wfsa1.dmsf_file_revision_id = 2
    
    assert @wfsa1.save
    @wfsa1.reload
    
    assert_equal 2, @wfsa1.dmsf_workflow_step_id    
    assert_equal 2, @wfsa1.user_id
    assert_equal 2, @wfsa1.dmsf_file_revision_id
  end
  
  def test_validate_workflow_step_id_presence
    @wfsa1.dmsf_workflow_step_id = nil
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count        
  end
  
  def test_validate_workflow_entity_id_presence
    @wfsa1.dmsf_file_revision_id = nil
    assert !@wfsa1.save
    assert_equal 1, @wfsa1.errors.count        
  end
  
  def test_destroy  
    @wfsa1.destroy
    assert_nil DmsfWorkflowStepAssignment.find_by_id(1)
    assert_nil DmsfWorkflowStepAction.find_by_id(1)
  end
end
