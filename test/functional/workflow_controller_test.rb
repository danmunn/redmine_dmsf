require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowsControllerTest < ActionController::TestCase
  fixtures :users
  fixtures :dmsf_workflows
  
  def setup
    User.current = nil    
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
    assert_response 403    
  end
  
  def test_new
    @request.session[:user_id] = 1 # admin
    get :new
    assert_response :success
    assert_template 'new'
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
  
end
