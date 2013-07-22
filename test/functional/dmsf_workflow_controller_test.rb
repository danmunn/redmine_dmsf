require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowsControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n
  
  fixtures :users, :dmsf_workflows, :dmsf_workflow_steps, :projects, :roles, 
    :members, :member_roles, :dmsf_workflow_step_assignments, :dmsf_file_revisions, 
    :dmsf_files
  
  def setup
    @user_admin = User.find_by_id 1 # Redmine admin
    @user_member = User.find_by_id 2 # John Smith - manager
    @user_non_member = User.find_by_id 3 #Dave Lopper
    @request.session[:user_id] = @user_member.id          
    @role_manager = Role.where(:name => 'Manager').first
    @role_manager.add_permission! :file_approval        
    @wfs1 = DmsfWorkflowStep.find_by_id 1 # step 1
    @wfs2 = DmsfWorkflowStep.find_by_id 2 # step 2
    @wfs3 = DmsfWorkflowStep.find_by_id 3 # step 1
    @wfs4 = DmsfWorkflowStep.find_by_id 4 # step 2
    @wfs5 = DmsfWorkflowStep.find_by_id 5 # step 3
    @manager_role = Role.find_by_name('Manager')    
    @project1 = Project.find_by_id 1
    @project5 = Project.find_by_id 5
    @project5.enable_module! :dmsf
    @wf1 = DmsfWorkflow.find_by_id 1
    @wfsa2 = DmsfWorkflowStepAssignment.find_by_id 2
    @revision1 = DmsfFileRevision.find_by_id 1
    @revision2 = DmsfFileRevision.find_by_id 2
    @revision3 = DmsfFileRevision.find_by_id 3   
    @file1 = DmsfFile.find_by_id 1
    @file2 = DmsfFile.find_by_id 2
  end
  
  def test_authorize
    # Admin
    @request.session[:user_id] = @user_admin.id
    get :index
    assert_response :success
    assert_template 'index'        
    
    # Non member
    @request.session[:user_id] = @user_non_member.id    
    get :index, :project_id => @project5.id
    assert_response :forbidden           
    
    # Member    
    @request.session[:user_id] = @user_member.id        
    # Administration
    get :index
    assert_response :forbidden    
    # Project    
    get :index, :project_id => @project5.id
    assert_response :success
    assert_template 'index'
    # Without the module
    @project5.disable_module!(:dmsf)    
    get :index, :project_id => @project5.id
    assert_response :forbidden    
    # Without permissions
    @project5.enable_module!(:dmsf)
    @role_manager.remove_permission! :file_approval
    get :index, :project_id => @project5.id
    assert_response :forbidden    
  end
  
  def test_index    
    get :index, :project_id => @project5.id
    assert_response :success
    assert_template 'index'
  end

  def test_new    
    get :new, :project_id => @project5.id
    assert_response :success
    assert_template 'new'
  end    

  def test_edit
    get :edit, :id => @wf1.id
    assert_response :success
    assert_template 'edit'    
  end
  
  def test_create        
    assert_difference 'DmsfWorkflow.count', +1 do    
      post :create, :dmsf_workflow => {:name => 'wf3'}, :project_id => @project5.id
    end    
    assert_redirected_to settings_project_path(@project5, :tab => 'dmsf')    
  end
  
  def test_update        
    put :update, :id => @wf1.id, :dmsf_workflow => {:name => 'wf1a'}
    @wf1.reload
    assert_equal 'wf1a', @wf1.name    
  end
  
  def test_destroy    
    id = @wf1.id
    assert_difference 'DmsfWorkflow.count', -1 do
      delete :destroy, :id => @wf1.id
    end
    assert_redirected_to settings_project_path(@project5, :tab => 'dmsf')
    assert_equal 0, DmsfWorkflowStep.where(:dmsf_workflow_id => id).all.count
  end
    
  def test_add_step    
    assert_difference 'DmsfWorkflowStep.count', +1 do    
      post :add_step, :commit => l(:dmsf_or), :step => 1, :id => @wf1.id, :user_ids =>[@user_non_member.id]
    end
    assert_response :success
    ws = DmsfWorkflowStep.first(:order => 'id DESC')    
    assert_equal @wf1.id, ws.dmsf_workflow_id
    assert_equal 1, ws.step
    assert_equal @user_non_member.id, ws.user_id
    assert_equal DmsfWorkflowStep::OPERATOR_OR, ws.operator
  end
  
  def test_remove_step    
    n = DmsfWorkflowStep.where(:dmsf_workflow_id => @wf1.id, :step => 1).count
    assert_difference 'DmsfWorkflowStep.count', -n do
      delete :remove_step, :step => @wfs1.id, :id => @wf1.id
    end
    assert_response :success
    ws = DmsfWorkflowStep.where(:dmsf_workflow_id => @wf1.id).first(:order => 'id ASC')    
    assert_equal 1, ws.step
  end
  
  def test_reorder_steps_to_lower       
    put :reorder_steps, :step => 1, :id => @wf1.id, :workflow_step => {:move_to => 'lower'}
    assert_response :success  
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload        
    assert_equal 1, @wfs2.step
    assert_equal 1, @wfs3.step
    assert_equal 2, @wfs1.step
    assert_equal 2, @wfs4.step
    assert_equal 3, @wfs5.step
  end
  
  def test_reorder_steps_to_lowest        
    put :reorder_steps, :step => 1, :id => @wf1.id, :workflow_step => {:move_to => 'lowest'}
    assert_response :success  
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload        
    assert_equal 1, @wfs2.step    
    assert_equal 1, @wfs3.step
    assert_equal 2, @wfs5.step
    assert_equal 3, @wfs1.step
    assert_equal 3, @wfs4.step
  end            
  
  def test_reorder_steps_to_higher    
    put :reorder_steps, :step => 3, :id => @wf1.id, :workflow_step => {:move_to => 'higher'}
    assert_response :success  
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload        
    assert_equal 1, @wfs1.step
    assert_equal 1, @wfs4.step
    assert_equal 2, @wfs5.step
    assert_equal 3, @wfs2.step    
    assert_equal 3, @wfs3.step    
  end
  
  def test_reorder_steps_to_highest    
    put :reorder_steps, :step => 3, :id => @wf1.id, :workflow_step => {:move_to => 'highest'}
    assert_response :success  
    @wfs1.reload
    @wfs2.reload
    @wfs3.reload
    @wfs4.reload
    @wfs5.reload        
    assert_equal 1, @wfs5.step
    assert_equal 2, @wfs1.step
    assert_equal 2, @wfs4.step
    assert_equal 3, @wfs2.step    
    assert_equal 3, @wfs3.step    
  end
  
  def test_action_approve        
    @request.env['HTTP_REFERER'] = 'http://test.host/projects/2/dmsf'
    post( 
      :new_action, 
      :commit => l(:button_submit), 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :dmsf_file_revision_id => @revision2.id,
      :step_action => DmsfWorkflowStepAction::ACTION_APPROVE,
      :user_id => nil,
      :note => '')    
    assert_response :redirect
    assert DmsfWorkflowStepAction.where(
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :action => DmsfWorkflowStepAction::ACTION_APPROVE).first    
  end
#  
#  def test_action_reject 
#    # TODO: There is a strange error: 'ActiveRecord::RecordNotFound: Couldn't find Project with id=0'
#    # while saving the revision   
#    @request.env['HTTP_REFERER'] = 'http://test.host/projects/2/dmsf'
#    post( 
#      :new_action, 
#      :commit => l(:button_submit), 
#      :id => @wf1.id, 
#      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
#      :dmsf_file_revision_id => @revision2.id,
#      :step_action => DmsfWorkflowStepAction::ACTION_REJECT,
#      :note => 'Rejected because...')      
#    assert_response :redirect
#    assert DmsfWorkflowStepAction.where(
#      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
#      :action => DmsfWorkflowStepAction::ACTION_REJECT).first    
#  end
#  
  def test_action            
    xhr(
      :get,
      :action,
      :project_id => @project5.id, 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id,
      :dmsf_file_revision_id => @revision2.id,
      :title => l(:title_waiting_for_approval))      
      assert_response :success
      assert_match /ajax-modal/, response.body
      assert_template 'action'
  end
  
  def test_new_action_delegate     
    @request.env['HTTP_REFERER'] = 'http://test.host/projects/2/dmsf'
    post( 
      :new_action, 
      :commit => l(:button_submit), 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :dmsf_file_revision_id => @revision2.id,
      :step_action => @user_admin.id * 10,
      :note => 'Delegated because...')    
    assert_response :redirect
    assert DmsfWorkflowStepAction.where(
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :action => DmsfWorkflowStepAction::ACTION_DELEGATE).first 
    @wfsa2.reload
    assert_equal @wfsa2.user_id, @user_admin.id        
  end
  
  def test_assign        
    xhr( 
      :get, 
      :assign, 
      :project_id => @project5.id,
      :id => @wf1.id, 
      :dmsf_file_revision_id => @revision1.id, 
      :title => l(:label_dmsf_wokflow_action_assign))
    assert_response :success
    assert_match /ajax-modal/, response.body
    assert_template 'assign'    
  end
  
#  def test_assignment    
#    # TODO: There is a strange error: 'ActiveRecord::RecordNotFound: Couldn't find Project with id=0'
#    # while saving the revision
#    @request.env['HTTP_REFERER'] = 'http://test.host/projects/3/dmsf'
#    post( 
#      :assignment, 
#      :commit => l(:button_submit), 
#      :id => @wf1.id, 
#      :dmsf_workflow_id => @wf1.id, 
#      :dmsf_file_revision_id => @revision3.id,
#      :action => 'assignment',
#      :project_id => @project5.id)    
#    assert_response :redirect
#     @file1.reload
#     assert file1.locked?
#     assert true
#  end
end
