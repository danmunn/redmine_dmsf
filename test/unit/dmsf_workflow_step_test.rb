require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowStepTest < RedmineDmsf::Test::UnitTest
  include Redmine::I18n
  
  fixtures :users, :dmsf_workflows, :dmsf_workflow_steps

  def setup 
    @wfs1 = DmsfWorkflowStep.find(1)
    @wfs2 = DmsfWorkflowStep.find(2)
    @wfs5 = DmsfWorkflowStep.find(5)
    @revision1 = DmsfFileRevision.find_by_id 1
  end
  
  def test_truth
    assert_kind_of DmsfWorkflowStep, @wfs1
  end
  
  def test_create
    wfs = DmsfWorkflowStep.new(
      :dmsf_workflow_id => 1, 
      :step => 2, 
      :user_id => 3, 
      :operator => 1)   
    assert wfs.save
  end
  
  def test_update    
    @wfs1.dmsf_workflow_id = 2    
    @wfs1.step = 2    
    @wfs1.user_id = 2    
    @wfs1.operator = 2
    
    assert @wfs1.save
    @wfs1.reload
    
    assert_equal 2, @wfs1.dmsf_workflow_id
    assert_equal 2, @wfs1.step
    assert_equal 2, @wfs1.user_id
    assert_equal 2, @wfs1.operator
  end
  
  def test_validate_workflow_id_presence
    @wfs1.dmsf_workflow_id = nil
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
    @wfs2.dmsf_workflow_id = @wfs1.dmsf_workflow_id
    @wfs2.step = @wfs1.step
    assert !@wfs2.save
    assert_equal 1, @wfs2.errors.count        
  end
  
  def test_destroy
    assert DmsfWorkflowStepAssignment.where(:dmsf_workflow_step_id => @wfs2.id).all.count > 0
    @wfs2.destroy
    assert_nil DmsfWorkflowStep.find_by_id(2)
    assert_equal DmsfWorkflowStepAssignment.where(:dmsf_workflow_step_id => @wfs2.id).all.count, 0
  end
  
  def test_soperator
    assert_equal @wfs1.soperator, l(:dmsf_or)
  end
  
  def test_user
    assert_equal @wfs1.user, User.find_by_id(@wfs1.user_id)
  end
  
  def test_assign
    @wfs5.assign(@revision1.id)
    assert DmsfWorkflowStepAssignment.where(
      :dmsf_workflow_step_id => @wfs5.id, 
      :dmsf_file_revision_id => @revision1.id).first
  end
end
