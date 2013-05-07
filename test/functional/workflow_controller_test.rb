require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowsControllerTest < Test::TestCase
  fixtures :users, :dmsf_workflows, :dmsf_workflow_steps, :projects, :roles, 
    :members, :member_roles
  
  def setup
    User.current = nil        
    
    @manager_role = Role.find_by_name('Manager')    
    @project = Project.find(5)            
  end
  
  def test_index_admin
    @request.session[:user_id] = 1 # admin
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_index_user
    @request.session[:user_id] = 2 # non admin
    get :index
    assert_response :forbidden
  end
  
  def test_index_member
    old_controller = @controller
    @controller = ProjectsController.new        
           
    @request.session[:user_id] = 2
    get :settings, :id => @project.id    
    assert_response :success
    assert_template 'settings'       
    
    @controller = old_controller
  end
  
  def test_new_admin
    @request.session[:user_id] = 1 # admin
    get :new
    assert_response :success
    assert_template 'new'
  end    
  
  def test_new_member_no_permission    
    @project.enable_module!(:dmsf)    
    @manager_role.remove_permission! :approval_workflows
    @request.session[:user_id] = 2
    get :new, {:project_id => @project.id}
    assert_response :forbidden    
  end
  
  def test_new_member_no_module
    @project.disable_module!(:dmsf)    
    @manager_role.add_permission! :approval_workflows    
    @request.session[:user_id] = 2
    get :new, {:project_id => @project.id}
    assert_response :forbidden    
  end
  
  def test_new_member
    @manager_role.add_permission! :approval_workflows
    @request.session[:user_id] = 2
    @project.enable_module!(:dmsf)    
    get :new, {:project_id => @project.id}
    assert_response :success
    assert_template 'new'
  end
  
  def test_new_no_member
    @manager_role.add_permission! :approval_workflows
    @request.session[:user_id] = 3
    @project.enable_module!(:dmsf)    
    get :new, {:project_id => @project.id}
    assert_response :forbidden    
  end
    
  def test_edit
    @request.session[:user_id] = 1 # admin
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'    
  end
  
  def test_create    
    @request.session[:user_id] = 1 # admin
    assert_difference 'Dmsf::Workflow.count', +1 do    
      post :create, :dmsf_workflow => {:name => 'wf3'}        
    end
    workflow = Dmsf::Workflow.first(:order => 'id DESC')
    assert_redirected_to dmsf_workflows_path
    assert_equal 'wf3', workflow.name    
  end
  
  def test_update    
    @request.session[:user_id] = 1 # admin
    put :update, :id => 1, :dmsf_workflow => {:name => 'wf1a'}
    workflow = Dmsf::Workflow.find(1)
    assert_equal 'wf1a', workflow.name    
  end
  
  def test_destroy
    @request.session[:user_id] = 1 # admin
    assert_difference 'Dmsf::Workflow.count', -1 do
      delete :destroy, :id => 1
    end
    assert_redirected_to dmsf_workflows_path
    assert_nil Dmsf::Workflow.find_by_id(1)
  end
    
  def test_add_step
    @request.session[:user_id] = 1 # admin
    assert_difference 'Dmsf::WorkflowStep.count', +1 do    
      post :add_step, :commit => 'OR', :step => 1, :id => 1, :user_ids =>[3]
    end
    assert_response :success
    ws = Dmsf::WorkflowStep.first(:order => 'id DESC')    
    assert_equal 1, ws.workflow_id
    assert_equal 1, ws.step
    assert_equal 3, ws.user_id
    assert_equal 0, ws.operator
  end
  
  def test_remove_step
    @request.session[:user_id] = 1 # admin
    n = Dmsf::WorkflowStep.where(:workflow_id => 1, :step => 1).count
    assert_difference 'Dmsf::WorkflowStep.count', -n do
      delete :remove_step, :step => 1, :id => 1
    end
    assert_response :success
    ws = Dmsf::WorkflowStep.where(:workflow_id => 1).first(:order => 'id ASC')    
    assert_equal 1, ws.step
  end
  
  def test_reorder_steps_to_lower
    @request.session[:user_id] = 1 # admin    
    put :reorder_steps, :step => 1, :id => 1, :workflow_step => {:move_to => 'lower'}
    assert_response :success        
    assert_equal 2, Dmsf::WorkflowStep.find(1).step    
    assert_equal 1, Dmsf::WorkflowStep.find(2).step    
    assert_equal 3, Dmsf::WorkflowStep.find(3).step
  end
  
  def test_reorder_steps_to_lowest    
    @request.session[:user_id] = 1 # admin    
    put :reorder_steps, :step => 1, :id => 1, :workflow_step => {:move_to => 'lowest'}
    assert_response :success        
    assert_equal 3, Dmsf::WorkflowStep.find(1).step
    assert_equal 1, Dmsf::WorkflowStep.find(2).step    
    assert_equal 2, Dmsf::WorkflowStep.find(3).step
  end            
  
  def test_reorder_steps_to_higher
    @request.session[:user_id] = 1 # admin    
    put :reorder_steps, :step => 2, :id => 1, :workflow_step => {:move_to => 'higher'}
    assert_response :success    
    assert_equal 2, Dmsf::WorkflowStep.find(1).step    
    assert_equal 1, Dmsf::WorkflowStep.find(2).step    
    assert_equal 3, Dmsf::WorkflowStep.find(3).step
  end
  
  def test_reorder_steps_to_highest
    @request.session[:user_id] = 1 # admin    
    put :reorder_steps, :step => 3, :id => 1, :workflow_step => {:move_to => 'highest'}
    assert_response :success    
    assert_equal 2, Dmsf::WorkflowStep.find(1).step    
    assert_equal 3, Dmsf::WorkflowStep.find(2).step    
    assert_equal 1, Dmsf::WorkflowStep.find(3).step
  end
end
