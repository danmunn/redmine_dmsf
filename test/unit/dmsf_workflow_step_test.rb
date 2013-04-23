require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowStepTest < Test::UnitTest
  
  fixtures :dmsf_workflow_steps

  def setup 
    @ws1 = Dmsf::WorkflowStep.find(1)
    @ws2 = Dmsf::WorkflowStep.find(2)
  end
  
  def test_truth
    assert_kind_of Dmsf::WorkflowStep, @ws1
  end
  
  def test_create
    wfs = Dmsf::WorkflowStep.new(
      :workflow_id => 1, 
      :step => 2, 
      :user_id => 1, 
      :operator => 1)   
    assert wfs.save
  end
  
  def test_update
    assert_equal 1, @ws1.workflow_id
    @ws1.workflow_id = 2
    assert_equal 1, @ws1.step
    @ws1.step = 2
    assert_equal 1, @ws1.user_id
    @ws1.user_id = 2
    assert_equal 1, @ws1.operator
    @ws1.operator = 2
    
    assert @ws1.save
    @ws1.reload
    
    assert_equal 2, @ws1.workflow_id
    assert_equal 2, @ws1.step
    assert_equal 2, @ws1.user_id
    assert_equal 2, @ws1.operator
  end
  
  def test_validate_workflow_id_presence
    @ws1.workflow_id = nil
    assert !@ws1.save
    assert_equal 1, @ws1.errors.count        
  end
  
  def test_validate_step_presence
    @ws1.step = nil
    assert !@ws1.save
    assert_equal 1, @ws1.errors.count        
  end
  
  def test_validate_user_id_presence
    @ws1.user_id = nil
    assert !@ws1.save
    assert_equal 1, @ws1.errors.count        
  end
  
  def test_validate_operator_presence
    @ws1.operator = nil
    assert !@ws1.save
    assert_equal 1, @ws1.errors.count        
  end
  
  def test_validate_user_id_uniqueness
    @ws2.user_id = @ws1.user_id
    @ws2.workflow_id = @ws1.workflow_id
    @ws2.step = @ws1.step
    assert !@ws2.save
    assert_equal 1, @ws2.errors.count        
  end
  
  def test_destroy  
    @ws2.destroy
    assert_nil Dmsf::WorkflowStep.find_by_id(2)
  end
end
