require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowTest < Test::UnitTest

  fixtures :projects, :dmsf_workflows, :dmsf_workflow_steps

  def setup
    @wf1 = Dmsf::Workflow.find(1)
    @wf2 = Dmsf::Workflow.find(2) 
    @wfs1 = Dmsf::WorkflowStep.find(1)
  end
  
  def test_truth
    assert_kind_of Dmsf::Workflow, @wf1
  end
  
  def test_create
    workflow = Dmsf::Workflow.new(:name => 'wf')   
    assert workflow.save
  end
  
  def test_update    
    @wf1.name = 'wf1a'
    @wf1.project_id = 5
    assert @wf1.save
    @wf1.reload
    assert_equal 'wf1a', @wf1.name
    assert_equal 5, @wf1.project_id
  end
  
  def test_validate_name_length
    @wf1.name = 'a' * 256
    assert !@wf1.save
    assert_equal 1, @wf1.errors.count        
  end
  
  def test_validate_name_presence
    @wf1.name = ''
    assert !@wf1.save
    assert_equal 1, @wf1.errors.count        
  end
  
  def test_validate_name_uniqueness
    @wf2.name = @wf1.name
    assert !@wf2.save
    assert_equal 1, @wf2.errors.count        
  end
  
  def test_destroy      
    @wf1.destroy
    assert_nil Dmsf::Workflow.find_by_id(1)
    assert_nil Dmsf::WorkflowStep.find_by_id(@wfs1.id)
  end
end
