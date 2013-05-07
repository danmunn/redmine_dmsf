require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowStepTest < Test::UnitTest
  
  fixtures :users, :dmsf_workflows, :dmsf_workflow_steps

  def setup 
    @wfs1 = Dmsf::WorkflowStep.find(1)
    @wfs2 = Dmsf::WorkflowStep.find(2)
  end
  
  def test_truth
    assert_kind_of Dmsf::WorkflowStep, @wfs1
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
    @wfs1.workflow_id = 2    
    @wfs1.step = 2    
    @wfs1.user_id = 2    
    @wfs1.operator = 2
    
    assert @wfs1.save
    @wfs1.reload
    
    assert_equal 2, @wfs1.workflow_id
    assert_equal 2, @wfs1.step
    assert_equal 2, @wfs1.user_id
    assert_equal 2, @wfs1.operator
  end
  
  def test_validate_workflow_id_presence
    @wfs1.workflow_id = nil
    assert !@wfs1.save
    assert_equal 1, @wfs1.errors.count        
  end
  
  def test_validate_step_presence
    @wfs1.step = nil
    assert !@wfs1.save
    assert_equal 1, @wfs1.errors.count        
  end
  
  def test_validate_user_id_presence
    @wfs1.user_id = nil
    assert !@wfs1.save
    assert_equal 1, @wfs1.errors.count        
  end
  
  def test_validate_operator_presence
    @wfs1.operator = nil
    assert !@wfs1.save
    assert_equal 1, @wfs1.errors.count        
  end
  
  def test_validate_user_id_uniqueness
    @wfs2.user_id = @wfs1.user_id
    @wfs2.workflow_id = @wfs1.workflow_id
    @wfs2.step = @wfs1.step
    assert !@wfs2.save
    assert_equal 1, @wfs2.errors.count        
  end
  
  def test_destroy  
    @wfs2.destroy
    assert_nil Dmsf::WorkflowStep.find_by_id(2)
  end
end
