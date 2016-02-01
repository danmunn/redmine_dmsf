# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class DmsfWorkflowsControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n
  
  fixtures :users, :email_addresses, :dmsf_workflows, :dmsf_workflow_steps, 
    :projects, :roles, :members, :member_roles, :dmsf_workflow_step_assignments, 
    :dmsf_file_revisions, :dmsf_files
  
  def setup
    @user_admin = User.find_by_id 1 # Redmine admin    
    @user_member = User.find_by_id 2 # John Smith - manager    
    @user_non_member = User.find_by_id 3 # Dave Lopper    
    @role_manager = Role.find_by_name('Manager')
    @role_manager.add_permission! :file_manipulation
    @role_manager.add_permission! :manage_workflows
    @role_manager.add_permission! :file_approval
    @wfs1 = DmsfWorkflowStep.find_by_id 1 # step 1
    @wfs2 = DmsfWorkflowStep.find_by_id 2 # step 2
    @wfs3 = DmsfWorkflowStep.find_by_id 3 # step 1
    @wfs4 = DmsfWorkflowStep.find_by_id 4 # step 2
    @wfs5 = DmsfWorkflowStep.find_by_id 5 # step 3    
    @project1 = Project.find_by_id 1    
    @project1.enable_module! :dmsf
    @wf1 = DmsfWorkflow.find_by_id 1
    @wfsa2 = DmsfWorkflowStepAssignment.find_by_id 2
    @revision1 = DmsfFileRevision.find_by_id 1
    @revision2 = DmsfFileRevision.find_by_id 2
    @revision3 = DmsfFileRevision.find_by_id 3   
    @file1 = DmsfFile.find_by_id 1
    @file2 = DmsfFile.find_by_id 2
    @request.env['HTTP_REFERER'] = dmsf_folder_path(:id => @project1.id)
    User.current = nil
    @request.session[:user_id] = @user_member.id          
  end
  
  def test_truth
    assert_kind_of User, @user_admin
    assert_kind_of User, @user_member
    assert_kind_of User, @user_non_member
    assert_kind_of Role, @role_manager
    assert_kind_of DmsfWorkflowStep, @wfs1
    assert_kind_of DmsfWorkflowStep, @wfs2
    assert_kind_of DmsfWorkflowStep, @wfs3
    assert_kind_of DmsfWorkflowStep, @wfs4
    assert_kind_of DmsfWorkflowStep, @wfs5
    assert_kind_of Project, @project1    
    assert_kind_of DmsfWorkflow, @wf1
    assert_kind_of DmsfWorkflowStepAssignment, @wfsa2
    assert_kind_of DmsfFileRevision, @revision1
    assert_kind_of DmsfFileRevision, @revision2
    assert_kind_of DmsfFileRevision, @revision3
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file2
  end
  
  def test_authorize_admin
    # Admin
    @request.session[:user_id] = @user_admin.id
    get :index
    assert_response :success
    assert_template 'index'        
  end
    
  def test_authorize_member
    # Non member
    @request.session[:user_id] = @user_non_member.id    
    get :index, :project_id => @project1.id
    assert_response :forbidden           
  end
  
  def test_authorize_administration    
    # Administration
    get :index
    assert_response :forbidden    
  end
  
  def test_authorize_projects    
    # Project    
    get :index, :project_id => @project1.id
    assert_response :success
    assert_template 'index'
  end
       
  def test_authorize_manage_workflows_forbidden
    # Without permissions
    @role_manager.remove_permission! :manage_workflows
    get :index, :project_id => @project1.id
    assert_response :forbidden
  end
  
  def test_authorization_file_approval_ok
    @role_manager.add_permission! :file_approval    
    @revision2.dmsf_workflow_id = @wf1.id
    get :start, :id => @revision2.dmsf_workflow_id,
      :dmsf_file_revision_id => @revision2.id
    assert_response :redirect
  end
  
  def test_authorization_file_approval_forbidden
    @role_manager.remove_permission! :file_approval
    @revision2.dmsf_workflow_id = @wf1.id
    get :start, :id => @revision2.dmsf_workflow_id,
      :dmsf_file_revision_id => @revision2.id
    assert_response :forbidden
  end
    
  def test_authorization_no_module
    # Without the module    
    @role_manager.add_permission! :file_manipulation
    @project1.disable_module!(:dmsf)    
    get :index, :project_id => @project1.id
    assert_response :forbidden        
  end
  
  def test_index    
    get :index, :project_id => @project1.id
    assert_response :success
    assert_template 'index'
  end

  def test_new    
    get :new, :project_id => @project1.id
    assert_response :success
    assert_template 'new'
  end    

  def test_show
    get :show, :id => @wf1.id
    assert_response :success
    assert_template 'show'    
  end
  
  def test_create        
    assert_difference 'DmsfWorkflow.count', +1 do    
      post :create, :dmsf_workflow => {:name => 'wf3'}, :project_id => @project1.id
    end    
    assert_redirected_to settings_project_path(@project1, :tab => 'dmsf_workflow')    
  end
  
  def test_update        
    put :update, :id => @wf1.id, :dmsf_workflow => {:name => 'wf1a'}
    @wf1.reload
    assert_equal 'wf1a', @wf1.name    
  end
  
  def test_destroy        
    assert_difference 'DmsfWorkflow.count', -1 do
      delete :destroy, :id => @wf1.id
    end
    assert_redirected_to settings_project_path(@project1, :tab => 'dmsf_workflow')    
    assert_equal 0, DmsfWorkflowStep.where(:dmsf_workflow_id => @wf1.id).all.count        
  end
    
  def test_add_step    
    assert_difference 'DmsfWorkflowStep.count', +1 do    
      post :add_step, :commit => l(:dmsf_or), :step => 1, :id => @wf1.id, :user_ids => [@user_non_member.id]
    end
    assert_response :success
    ws = DmsfWorkflowStep.order('id DESC').first    
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
    ws = DmsfWorkflowStep.where(:dmsf_workflow_id => @wf1.id).order('id ASC').first
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
    post( 
      :new_action, 
      :commit => l(:button_submit), 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :dmsf_file_revision_id => @revision1.id,
      :step_action => DmsfWorkflowStepAction::ACTION_APPROVE,
      :user_id => nil,
      :note => '')    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
    assert DmsfWorkflowStepAction.where(
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :action => DmsfWorkflowStepAction::ACTION_APPROVE).first    
  end
 
  def test_action_reject         
    post( 
      :new_action, 
      :commit => l(:button_submit), 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :dmsf_file_revision_id => @revision2.id,
      :step_action => DmsfWorkflowStepAction::ACTION_REJECT,
      :note => 'Rejected because...')      
    assert_response :redirect
    assert DmsfWorkflowStepAction.where(
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :action => DmsfWorkflowStepAction::ACTION_REJECT).first    
  end

  def test_action            
    xhr(
      :get,
      :action,
      :project_id => @project1.id, 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id,
      :dmsf_file_revision_id => @revision2.id,
      :title => l(:title_waiting_for_approval))      
      assert_response :success
      assert_match /ajax-modal/, response.body
      assert_template 'action'
  end
  
  def test_new_action_delegate         
    post( 
      :new_action, 
      :commit => l(:button_submit), 
      :id => @wf1.id, 
      :dmsf_workflow_step_assignment_id => @wfsa2.id, 
      :dmsf_file_revision_id => @revision2.id,
      :step_action => @user_admin.id * 10,
      :note => 'Delegated because...')    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
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
      :project_id => @project1.id,
      :id => @wf1.id, 
      :dmsf_file_revision_id => @revision1.id, 
      :title => l(:label_dmsf_wokflow_action_assign))
    assert_response :success
    assert_match /ajax-modal/, response.body
    assert_template 'assign'    
  end
  
  def test_start
    @revision2.dmsf_workflow_id = @wf1.id    
    get :start, :id => @revision2.dmsf_workflow_id,:dmsf_file_revision_id => @revision2.id
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
  end
  
  def test_assignment                
    post( 
      :assignment, 
      :commit => l(:button_submit), 
      :id => @wf1.id, 
      :dmsf_workflow_id => @wf1.id, 
      :dmsf_file_revision_id => @revision2.id,
      :action => 'assignment',
      :project_id => @project1.id)    
    assert_response :redirect     
  end

end
