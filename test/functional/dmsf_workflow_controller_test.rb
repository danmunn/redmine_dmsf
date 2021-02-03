# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

  fixtures :dmsf_workflows, :dmsf_workflow_steps, :dmsf_workflow_step_assignments,
           :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def setup
    super
    @wfs1 = DmsfWorkflowStep.find 1 # step 1
    @wfs2 = DmsfWorkflowStep.find 2 # step 2
    @wfs3 = DmsfWorkflowStep.find 3 # step 1
    @wfs4 = DmsfWorkflowStep.find 4 # step 2
    @wfs5 = DmsfWorkflowStep.find 5 # step 3
    @wf1 = DmsfWorkflow.find 1
    @wf3 = DmsfWorkflow.find 3
    @wfsa2 = DmsfWorkflowStepAssignment.find 2
    @revision1 = DmsfFileRevision.find 1
    @revision2 = DmsfFileRevision.find 2
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1.id)
    @request.session[:user_id] = @jsmith.id
  end

  def test_authorize_admin
    # Admin
    @request.session[:user_id] = @admin.id
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_authorize_member
    # Non member
    @request.session[:user_id] = @someone.id
    get :index, params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_authorize_administration
    # Administration
    get :index
    assert_response :forbidden
  end

  def test_authorize_projects
    # Project
    get :index, params: { project_id: @project1.id }
    assert_response :success
    assert_template 'index'
  end

  def test_authorize_manage_workflows_forbidden
    # Without permissions
    @role_manager.remove_permission! :manage_workflows
    get :index, params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_authorization_file_approval_ok
    @role_manager.add_permission! :file_approval
    @revision2.dmsf_workflow_id = @wf1.id
    get :start, params: { id: @revision2.dmsf_workflow_id,
      dmsf_file_revision_id: @revision2.id }
    assert_response :redirect
  end

  def test_authorization_file_approval_forbidden
    @role_manager.remove_permission! :file_approval
    @revision2.dmsf_workflow_id = @wf1.id
    get :start, params: { id: @revision2.dmsf_workflow_id,
      dmsf_file_revision_id: @revision2.id }
    assert_response :forbidden
  end

  def test_authorization_no_module
    # Without the module
    @role_manager.add_permission! :file_manipulation
    @project1.disable_module!(:dmsf)
    get :index, params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_index_administration
    @request.session[:user_id] = @admin.id
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_index_project
    get :index, params: { project_id: @project1.id }
    assert_response :success
    assert_template 'index'
  end

  def test_new
    get :new, params: { project_id: @project1.id }
    assert_response :success
    assert_template 'new'
  end

  def test_lock
    put :update, params: { id: @wf1.id, dmsf_workflow: { status: DmsfWorkflow::STATUS_LOCKED }}
    @wf1.reload
    assert @wf1.locked?, "#{@wf1.name} status is #{@wf1.status}"
  end

  def test_unlock
    @request.session[:user_id] = @admin.id
    put :update, params: { id: @wf3.id, dmsf_workflow: { status: DmsfWorkflow::STATUS_ACTIVE }}
    @wf3.reload
    assert @wf3.active?, "#{@wf3.name} status is #{@wf3.status}"
  end

  def test_show
    get :show, params: { id: @wf1.id }
    assert_response :success
    assert_template 'show'
  end

  def test_create
    assert_difference 'DmsfWorkflow.count', +1 do
      post :create, params: { dmsf_workflow: { name: 'wf4', project_id: @project1.id } }
    end
    assert_redirected_to settings_project_path(@project1, tab: 'dmsf_workflow')
  end

  def test_create_with_the_same_name
    assert_difference 'DmsfWorkflow.count', 0 do
      post :create, params: { dmsf_workflow: { name: @wf1.name, project_id: @project1.id } }
    end
    assert_response :success
    assert_select_error /#{l('activerecord.errors.messages.taken')}$/
  end

  def test_update
    put :update, params: { id: @wf1.id, dmsf_workflow: { name: 'wf1a' } }
    @wf1.reload
    assert_equal 'wf1a', @wf1.name
  end

  def test_destroy
    assert_difference 'DmsfWorkflow.count', -1 do
      delete :destroy, params: { id: @wf1.id }
    end
    assert_redirected_to settings_project_path(@project1, tab: 'dmsf_workflow')
    assert_equal 0, DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id).all.count
  end

  def test_add_step
    assert_difference 'DmsfWorkflowStep.count', +1 do
      post :add_step, params: { commit: l(:dmsf_or), step: 1, name: '1st step', id: @wf1.id,
           user_ids: [@someone.id] }
    end
    assert_response :success
    ws = DmsfWorkflowStep.order(id: :desc).first
    assert_equal @wf1.id, ws.dmsf_workflow_id
    assert_equal 1, ws.step
    assert_equal '1st step', ws.name
    assert_equal @someone.id, ws.user_id
    assert_equal DmsfWorkflowStep::OPERATOR_OR, ws.operator
  end

  def test_remove_step
    n = DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id, step: 1).count
    assert_difference 'DmsfWorkflowStep.count', -n do
      delete :remove_step, params: {step: @wfs1.id, id: @wf1.id }
    end
    assert_response :redirect
    ws = DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id).order(id: :asc).first
    assert_equal 1, ws.step
  end

  def test_reorder_steps_to_lower
    put :reorder_steps, params: { step: 1, id: @wf1.id, dmsf_workflow: { position: 2 } }
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
    put :reorder_steps, params: { step: 1, id: @wf1.id, dmsf_workflow: { position: 3 } }
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
    put :reorder_steps, params: { step: 3, id: @wf1.id, dmsf_workflow: { position: 2 } }
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
    put :reorder_steps, params: { step: 3, id: @wf1.id, dmsf_workflow: { position: '1' } }
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
      :new_action, params: {
        commit: l(:button_submit),
        id: @wf1.id,
        dmsf_workflow_step_assignment_id: @wfsa2.id,
        dmsf_file_revision_id: @revision1.id,
        step_action: DmsfWorkflowStepAction::ACTION_APPROVE,
        user_id: nil,
        note: ''})
    assert_redirected_to dmsf_folder_path(id: @project1.id)
    assert DmsfWorkflowStepAction.where(
      dmsf_workflow_step_assignment_id: @wfsa2.id,
      action: DmsfWorkflowStepAction::ACTION_APPROVE).first
  end

  def test_action_reject
    post(
      :new_action, params: {
        commit: l(:button_submit),
        id: @wf1.id,
        dmsf_workflow_step_assignment_id: @wfsa2.id,
        dmsf_file_revision_id: @revision2.id,
        step_action: DmsfWorkflowStepAction::ACTION_REJECT,
        note: 'Rejected because...'})
    assert_response :redirect
    assert DmsfWorkflowStepAction.where(
      dmsf_workflow_step_assignment_id: @wfsa2.id,
      action: DmsfWorkflowStepAction::ACTION_REJECT).first
  end

  def test_action
    get(
      :action, xhr: true, params: {
        project_id: @project1.id,
        id: @wf1.id,
        dmsf_workflow_step_assignment_id: @wfsa2.id,
        dmsf_file_revision_id: @revision2.id,
        title: l(:title_waiting_for_approval)})
      assert_response :success
      assert_match(/ajax-modal/, response.body)
      assert_template 'action'
  end

  def test_new_action_delegate
    post(
      :new_action, params: {
      commit: l(:button_submit),
      id: @wf1.id,
      dmsf_workflow_step_assignment_id: @wfsa2.id,
      dmsf_file_revision_id: @revision2.id,
      step_action: @admin.id * 10,
      note: 'Delegated because...'})
    assert_redirected_to dmsf_folder_path(id: @project1.id)
    assert DmsfWorkflowStepAction.where(
      dmsf_workflow_step_assignment_id: @wfsa2.id,
      action: DmsfWorkflowStepAction::ACTION_DELEGATE).first
    @wfsa2.reload
    assert_equal @wfsa2.user_id, @admin.id
  end

  def test_assign
    get(
      :assign, xhr: true, params: {
      project_id: @project1.id,
      id: @wf1.id,
      dmsf_file_revision_id: @revision1.id,
      title: l(:label_dmsf_wokflow_action_assign)})
    assert_response :success
    assert_match(/ajax-modal/, response.body)
    assert_template 'assign'
  end

  def test_start
    @revision2.dmsf_workflow_id = @wf1.id
    get :start, params: { id: @revision2.dmsf_workflow_id, dmsf_file_revision_id: @revision2.id }
    assert_redirected_to dmsf_folder_path(id: @project1.id)
  end

  def test_assignment
    post(
      :assignment, params: {
      commit: l(:button_submit),
      id: @wf1.id,
      dmsf_workflow_id: @wf1.id,
      dmsf_file_revision_id: @revision2.id,
      action: 'assignment',
      project_id: @project1.id })
    assert_response :redirect
  end

  def test_update_step_name
    put :update_step, params: {id: @wf1.id, step: @wfs2.step, dmsf_workflow: { step_name: 'new_name' } }
    assert_response :redirect
    # All steps in the same step must be renamed
    @wfs2.reload
    assert_equal 'new_name', @wfs2.name
    @wfs3.reload
    assert_equal 'new_name', @wfs3.name
    # But not in others
    @wfs1.reload
    assert_equal '1st step', @wfs1.name
  end

  def test_update_step_operators
    put :update_step, params: {
        id: @wf1,
        step: '1',
        operator_step: { @wfs1.id.to_s => DmsfWorkflowStep::OPERATOR_OR.to_s },
        assignee: { @wfs1.id.to_s => @wfs1.user_id.to_s }}
    assert_response :redirect
    @wfs1.reload
    assert_equal @wfs1.operator, DmsfWorkflowStep::OPERATOR_OR
  end

  def test_update_step_assignee
    put :update_step, params: {
        id: @wf1,
        step: '1',
        operator_step: { @wfs1.id.to_s => DmsfWorkflowStep::OPERATOR_OR.to_s },
        assignee: { @wfs1.id.to_s => @someone.id.to_s }}
    assert_response :redirect
    @wfs1.reload
    assert_equal @someone.id, @wfs1.user_id
  end

  def test_delete_step
    name = @wfs2.name
    assert_difference 'DmsfWorkflowStep.count', -1 do
      delete :delete_step, params: { id: @wf1, step: @wfs2.id }
    end
    @wfs3.reload
    assert_equal @wfs3.name, name
    assert_response :redirect
  end

  def test_log_non_member
    @request.session[:user_id] = @someone.id
    get :log, params: { id: @wf1.id, project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' }, xhr: true
    assert_response :forbidden
  end

  def test_log_member_local_wf
    @request.session[:user_id] = @jsmith.id
    get :log, params: { id: @wf1.id, project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' }, xhr: true
    assert_response :success
    assert_template :log
  end

  def test_log_member_global_wf
    @request.session[:user_id] = @jsmith.id
    get :log, params: { id: @wf3.id, project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' }, xhr: true
    assert_response :success
    assert_template :log
  end

  def test_log_admin
    @request.session[:user_id] = @admin.id
    get :log, params: { id: @wf1.id, project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' }, xhr: true
    assert_response :success
    assert_template :log
  end

end
