# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Workflows controller
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
  end

  def test_authorize_admin
    # Admin
    post '/login', params: { username: 'admin', password: 'admin' }
    get '/dmsf_workflows'
    assert_response :success
    assert_template 'index'
  end

  def test_authorize_member
    # Non member
    post '/login', params: { username: 'someone', password: 'foo' }
    get '/dmsf_workflows', params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_authorize_administration
    # Administration
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf_workflows'
    assert_response :forbidden
  end

  def test_authorize_projects
    # Project
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf_workflows', params: { project_id: @project1.id }
    assert_response :success
    assert_template 'index'
  end

  def test_authorize_manage_workflows_forbidden
    # Without permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :manage_workflows
    get '/dmsf_workflows', params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_authorization_file_approval_ok
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.add_permission! :file_approval
    @revision2.dmsf_workflow_id = @wf1.id
    get "/dmsf_workflows/#{@revision2.dmsf_workflow_id}/start", params: { dmsf_file_revision_id: @revision2.id }
    assert_response :redirect
  end

  def test_authorization_file_approval_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_approval
    @revision2.dmsf_workflow_id = @wf1.id
    get "/dmsf_workflows/#{@revision2.dmsf_workflow_id}/start", params: { dmsf_file_revision_id: @revision2.id }
    assert_response :forbidden
  end

  def test_authorization_no_module
    # Without the module
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.add_permission! :file_manipulation
    @project1.disable_module! :dmsf
    get '/dmsf_workflows', params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_index_administration
    post '/login', params: { username: 'admin', password: 'admin' }
    get '/dmsf_workflows'
    assert_response :success
    assert_template 'index'
  end

  def test_index_project
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf_workflows', params: { project_id: @project1.id }
    assert_response :success
    assert_template 'index'
  end

  def test_new
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf_workflows/new', params: { project_id: @project1.id }
    assert_response :success
    assert_template 'new'
  end

  def test_lock
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    patch "/dmsf_workflows/#{@wf1.id}", params: { dmsf_workflow: { status: DmsfWorkflow::STATUS_LOCKED } }
    @wf1.reload
    assert @wf1.locked?, "#{@wf1.name} status is #{@wf1.status}"
  end

  def test_unlock
    post '/login', params: { username: 'admin', password: 'admin' }
    patch "/dmsf_workflows/#{@wf3.id}", params: { dmsf_workflow: { status: DmsfWorkflow::STATUS_ACTIVE } }
    @wf3.reload
    assert @wf3.active?, "#{@wf3.name} status is #{@wf3.status}"
  end

  def test_show
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/dmsf_workflows/#{@wf1.id}"
    assert_response :success
    assert_template 'show'
  end

  def test_create
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfWorkflow.count', +1 do
      post '/dmsf_workflows', params: { dmsf_workflow: { name: 'wf4', project_id: @project1.id } }
    end
    assert_redirected_to settings_project_path(@project1, tab: 'dmsf_workflow')
  end

  def test_create_with_the_same_name
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfWorkflow.count', 0 do
      post '/dmsf_workflows', params: { dmsf_workflow: { name: @wf1.name, project_id: @project1.id } }
    end
    assert_response :success
    assert_select_error(/#{l('activerecord.errors.messages.taken')}$/)
  end

  def test_update
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    patch "/dmsf_workflows/#{@wf1.id}", params: { dmsf_workflow: { name: 'wf1a' } }
    @wf1.reload
    assert_equal 'wf1a', @wf1.name
  end

  def test_destroy
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfWorkflow.count', -1 do
      delete "/dmsf_workflows/#{@wf1.id}"
    end
    assert_redirected_to settings_project_path(@project1, tab: 'dmsf_workflow')
    assert_equal 0, DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id).all.size
  end

  def test_add_step
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfWorkflowStep.count', +1 do
      post "/dmsf_workflows/#{@wf1.id}/edit",
           params: { commit: l(:dmsf_or), step: 1, name: '1st step', user_ids: [@someone.id] }
    end
    assert_response :success
    ws = DmsfWorkflowStep.order(id: :desc).first
    assert_equal @wf1.id, ws&.dmsf_workflow_id
    assert_equal 1, ws.step
    assert_equal '1st step', ws.name
    assert_equal @someone.id, ws.user_id
    assert_equal DmsfWorkflowStep::OPERATOR_OR, ws.operator
  end

  def test_remove_step
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    n = DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id, step: @wfs1.step).count
    assert_difference 'DmsfWorkflowStep.count', -n do
      delete "/dmsf_workflows/#{@wf1.id}/edit", params: { step: @wfs1.id }
    end
    assert_response :redirect
    ws = DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id).order(id: :asc).first
    assert_equal 1, ws&.step
  end

  def test_reorder_steps_to_lower
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/edit", params: { step: 1, dmsf_workflow: { position: 2 } }
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
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/edit", params: { step: 1, dmsf_workflow: { position: 3 } }
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
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/edit", params: { step: 3, dmsf_workflow: { position: 2 } }
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
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/edit", params: { step: 3, dmsf_workflow: { position: '1' } }
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
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/dmsf_workflows/#{@wf1.id}/new_action",
         params: {
           commit: l(:button_submit),
           dmsf_workflow_step_assignment_id: @wfsa2.id,
           dmsf_file_revision_id: @revision1.id,
           step_action: DmsfWorkflowStepAction::ACTION_APPROVE,
           user_id: nil,
           note: ''
         }
    assert_redirected_to dmsf_folder_path(id: @project1)
    assert DmsfWorkflowStepAction.exists?(dmsf_workflow_step_assignment_id: @wfsa2.id,
                                          action: DmsfWorkflowStepAction::ACTION_APPROVE)
  end

  def test_action_reject
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/dmsf_workflows/#{@wf1.id}/new_action",
         params: {
           commit: l(:button_submit),
           dmsf_workflow_step_assignment_id: @wfsa2.id,
           dmsf_file_revision_id: @revision2.id,
           step_action: DmsfWorkflowStepAction::ACTION_REJECT,
           note: 'Rejected because...'
         }
    assert_response :redirect
    assert DmsfWorkflowStepAction.exists?(dmsf_workflow_step_assignment_id: @wfsa2.id,
                                          action: DmsfWorkflowStepAction::ACTION_REJECT)
  end

  def test_action
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/dmsf_workflows/#{@wf1.id}/action",
        xhr: true,
        params: {
          project_id: @project1.id,
          dmsf_workflow_step_assignment_id: @wfsa2.id,
          dmsf_file_revision_id: @revision2.id,
          title: l(:title_waiting_for_approval)
        }
    assert_response :success
    assert_match(/ajax-modal/, response.body)
    assert_template 'action'
  end

  def test_new_action_delegate
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/dmsf_workflows/#{@wf1.id}/new_action",
         params: {
           commit: l(:button_submit),
           dmsf_workflow_step_assignment_id: @wfsa2.id,
           dmsf_file_revision_id: @revision2.id,
           step_action: @admin.id * 10,
           note: 'Delegated because...'
         }
    assert_redirected_to dmsf_folder_path(id: @project1)
    assert DmsfWorkflowStepAction.exists?(dmsf_workflow_step_assignment_id: @wfsa2.id,
                                          action: DmsfWorkflowStepAction::ACTION_DELEGATE)
    @wfsa2.reload
    assert_equal @wfsa2.user_id, @admin.id
  end

  def test_assign
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/dmsf_workflows/#{@project1.id}/assign",
        xhr: true,
        params: {
          dmsf_file_revision_id: @revision1.id,
          title: l(:label_dmsf_wokflow_action_assign)
        }
    assert_response :success
    assert_match(/ajax-modal/, response.body)
    assert_template 'assign'
  end

  def test_start
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @revision2.dmsf_workflow_id = @wf1.id
    get "/dmsf_workflows/#{@revision2.dmsf_workflow_id}/start", params: { dmsf_file_revision_id: @revision2.id }
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_assignment
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/dmsf_workflows/#{@project1.id}/assignment",
         params: {
           commit: l(:button_submit),
           id: @wf1.id,
           dmsf_workflow_id: @wf1.id,
           dmsf_file_revision_id: @revision2.id,
           action: 'assignment'
         }
    assert_response :redirect
  end

  def test_update_step_name
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/update_step", params: { step: @wfs2.step, dmsf_workflow: { step_name: 'new_name' } }
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
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/update_step",
        params: {
          step: '1',
          operator_step: { @wfs1.id.to_s => DmsfWorkflowStep::OPERATOR_OR.to_s },
          assignee: { @wfs1.id.to_s => @wfs1.user_id.to_s }
        }
    assert_response :redirect
    @wfs1.reload
    assert_equal @wfs1.operator, DmsfWorkflowStep::OPERATOR_OR
  end

  def test_update_step_assignee
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    put "/dmsf_workflows/#{@wf1.id}/update_step",
        params: {
          step: '1',
          operator_step: { @wfs1.id.to_s => DmsfWorkflowStep::OPERATOR_OR.to_s },
          assignee: { @wfs1.id.to_s => @someone.id.to_s }
        }
    assert_response :redirect
    @wfs1.reload
    assert_equal @someone.id, @wfs1.user_id
  end

  def test_delete_step
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    n = DmsfWorkflowStep.where(dmsf_workflow_id: @wf1.id, step: @wfs2.step).count
    assert_difference 'DmsfWorkflowStep.count', -n do
      delete "/dmsf_workflows/#{@wfs1.id}/edit", params: { step: @wfs2.id }
    end
    assert_response :redirect
  end

  def test_log_non_member
    post '/login', params: { username: 'someone', password: 'foo' }
    get "/dmsf_workflows/#{@wf1.id}/log",
        params: { project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' },
        xhr: true
    assert_response :forbidden
  end

  def test_log_member_local_wf
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/dmsf_workflows/#{@wf1.id}/log",
        params: { project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' },
        xhr: true
    assert_response :success
    assert_template :log
  end

  def test_log_member_global_wf
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/dmsf_workflows/#{@wf3.id}/log",
        params: { project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' },
        xhr: true
    assert_response :success
    assert_template :log
  end

  def test_log_admin
    post '/login', params: { username: 'admin', password: 'admin' }
    get "/dmsf_workflows/#{@wf1.id}/log",
        params: { project_id: @project1.id, dmsf_file_id: @file1.id, format: 'js' },
        xhr: true
    assert_response :success
    assert_template :log
  end

  def test_new_step
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/dmsf_workflows/#{@wf1.id}/new_step", params: { format: 'js' }, xhr: true
    assert_response :success
    assert_template :new_step
  end
end
