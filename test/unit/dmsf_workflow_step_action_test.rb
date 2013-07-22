require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowStepActionTest < RedmineDmsf::Test::UnitTest
  include Redmine::I18n
  
  fixtures :dmsf_workflow_steps
  fixtures :dmsf_workflow_step_actions
  
  def setup
    @wfsac1 = DmsfWorkflowStepAction.find(1)
    @wfsac2 = DmsfWorkflowStepAction.find(2)
    @wfsac3 = DmsfWorkflowStepAction.find(3)
  end
  
  def test_truth
    assert_kind_of DmsfWorkflowStepAction, @wfsac1
    assert_kind_of DmsfWorkflowStepAction, @wfsac2
    assert_kind_of DmsfWorkflowStepAction, @wfsac3
  end
  
  def test_create
    wfsac = DmsfWorkflowStepAction.new(
      :dmsf_workflow_step_assignment_id => 1,
      :action => DmsfWorkflowStepAction::ACTION_DELEGATE,
      :note => 'Approval')
    assert wfsac.save
    wfsac.reload
    assert wfsac.created_at
  end
  
  def test_update    
    @wfsac1.dmsf_workflow_step_assignment_id = 2    
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_REJECT
    @wfsac1.note = 'Rejection'
    
    assert @wfsac1.save
    @wfsac1.reload
    
    assert_equal 2, @wfsac1.dmsf_workflow_step_assignment_id    
    assert_equal DmsfWorkflowStepAction::ACTION_REJECT, @wfsac1.action
    assert_equal 'Rejection', @wfsac1.note
  end
  
  def test_validate_workflow_step_assignment_id_presence
    @wfsac1.dmsf_workflow_step_assignment_id = nil
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count        
  end
  
  def test_validate_action_presence
    @wfsac1.action = nil
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count        
  end
  
  def test_validate_note
    @wfsac1.note = ''
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_REJECT
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count
    @wfsac1.note = 'Rejected because....'
    assert @wfsac1.save    
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_DELEGATE
    @wfsac1.note = ''
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count
    @wfsac1.note = 'Delegated because'
    assert @wfsac1.save    
    @wfsac1.note = ''
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_APPROVE
    assert @wfsac1.save
  end
  
  def test_validate_author_id
    @wfsac1.author_id = nil
    assert !@wfsac1.save
    assert_equal 1, @wfsac1.errors.count
  end
  
  def test_validate_dmsf_workflow_step_assignment_id_uniqueness    
    @wfsac2.dmsf_workflow_step_assignment_id = @wfsac1.dmsf_workflow_step_assignment_id;
    @wfsac2.action = @wfsac1.action;
    assert !@wfsac2.save
    assert_equal 1, @wfsac2.errors.count  
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_REJECT
    @wfsac2.action = @wfsac1.action;
    assert @wfsac1.save
    assert !@wfsac2.save
    assert_equal 1, @wfsac2.errors.count
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_DELEGATE
    assert @wfsac1.save
    @wfsac2.action = @wfsac1.action;
    assert @wfsac2.save
  end
  
  def test_destroy  
    @wfsac1.destroy
    assert_nil DmsfWorkflowStepAction.find_by_id(1)    
  end  

  def test_is_finished
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_APPROVE
    assert @wfsac1.is_finished?
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_REJECT
    assert @wfsac1.is_finished?
    @wfsac1.action = DmsfWorkflowStepAction::ACTION_DELEGATE
    assert !@wfsac1.is_finished?
  end
  
  def test_action_str
    assert_equal DmsfWorkflowStepAction.action_str(DmsfWorkflowStepAction::ACTION_APPROVE), l(:title_approval)          
    assert_equal DmsfWorkflowStepAction.action_str(DmsfWorkflowStepAction::ACTION_REJECT), l(:title_rejection)
    assert_equal DmsfWorkflowStepAction.action_str(DmsfWorkflowStepAction::ACTION_DELEGATE), l(:title_delegation)
    assert_equal DmsfWorkflowStepAction.action_str(DmsfWorkflowStepAction::ACTION_ASSIGN), l(:title_assignment)
    assert_equal DmsfWorkflowStepAction.action_str(DmsfWorkflowStepAction::ACTION_START), l(:title_start) 
  end
end
