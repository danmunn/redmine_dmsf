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

# Workflow tests
class DmsfWorkflowTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_file_revisions, :dmsf_workflows, :dmsf_workflow_steps, :dmsf_workflow_step_assignments,
           :dmsf_workflow_step_actions, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @wf1 = DmsfWorkflow.find 1
    @wf2 = DmsfWorkflow.find 2
    @wf3 = DmsfWorkflow.find 3
    @wfs1 = DmsfWorkflowStep.find 1
    @wfs2 = DmsfWorkflowStep.find 2
    @wfs3 = DmsfWorkflowStep.find 3
    @wfs4 = DmsfWorkflowStep.find 4
    @wfs5 = DmsfWorkflowStep.find 5
    @wfsa1 = DmsfWorkflowStepAssignment.find 1
    @wfsac1 = DmsfWorkflowStepAction.find 1
    @revision1 = DmsfFileRevision.find 1
    @revision2 = DmsfFileRevision.find 2
  end

  def test_create
    workflow = DmsfWorkflow.new
    workflow.name = 'wf'
    assert workflow.save, workflow.errors.full_messages.to_sentence
  end

  def test_update
    @wf1.name = 'wf1a'
    @wf1.project_id = @project5.id
    assert @wf1.save, @wf1.errors.full_messages.to_sentence
    @wf1.reload
    assert_equal 'wf1a', @wf1.name
    assert_equal @project5.id, @wf1.project_id
  end

  def test_validate_name_length
    @wf1.name = 'a' * 256
    assert_not @wf1.save
    assert_equal 1, @wf1.errors.count
  end

  def test_validate_name_presence
    @wf1.name = ''
    assert_not @wf1.save
    assert_equal 1, @wf1.errors.count
  end

  def test_validate_name_uniqueness_globaly
    @wf2.name = @wf1.name
    assert_not @wf2.save
    assert_equal 1, @wf2.errors.count
  end

  def test_validate_name_uniqueness_localy
    @wf2.name = @wf1.name
    @wf2.project_id = @wf1.project_id
    assert_not @wf2.save
    assert_equal 1, @wf2.errors.count
  end

  def test_destroy
    @wf1.destroy
    assert_nil DmsfWorkflow.find_by(id: 1)
    assert_nil DmsfWorkflowStep.find_by(id: @wfs1.id)
  end

  def test_project
    # Global workflow
    assert_nil @wf2.project
    # Project workflow
    @wf2.project_id = @project5.id
    assert @wf2.project
  end

  def test_to_s
    assert_equal @wf1.name, @wf1.to_s
  end

  def test_reorder_steps_highest
    @wf1.reorder_steps(3, 1)
    assert_equal [2, 2, 3, 3, 1], @wf1.dmsf_workflow_steps.collect(&:step)
  end

  def test_reorder_steps_higher
    @wf1.reorder_steps(3, 2)
    assert_equal [1, 1, 3, 3, 2], @wf1.dmsf_workflow_steps.collect(&:step)
  end

  def test_reorder_steps_lower
    @wf1.reorder_steps(1, 2)
    assert_equal [2, 2, 1, 1, 3], @wf1.dmsf_workflow_steps.collect(&:step)
  end

  def test_reorder_steps_lowest
    @wf1.reorder_steps(1, 3)
    assert_equal [3, 3, 1, 1, 2], @wf1.dmsf_workflow_steps.collect(&:step)
  end

  def test_delegates
    delegates = @wf1.delegates(nil, nil, nil)
    assert_equal(delegates.size + 1, @project5.users.size)
    delegates = @wf1.delegates('Dave', nil, nil)
    assert_equal delegates.size, 1
    delegates = @wf1.delegates(nil, @wfsa1.id, 2)
    assert_not(delegates.any? { |user| user.id == @wfsa1.user_id })
    assert(delegates.any? { |user| user.id == 8 })
  end

  def test_next_assignments
    assignments = @wf1.next_assignments(2)
    assert_equal assignments.size, 1
    assert_equal assignments[0].user_id, 2
  end

  def test_assign
    @wf2.assign @revision2.id
    @wf2.dmsf_workflow_steps.each do |step|
      assert DmsfWorkflowStepAssignment.exists?(dmsf_workflow_step_id: step.id, dmsf_file_revision_id: @revision2.id)
    end
  end

  def test_try_finish_yes
    # The forkflow is waiting for an approval
    assert_equal DmsfWorkflow::STATE_WAITING_FOR_APPROVAL, @revision1.workflow
    # Do the approval
    wsa = DmsfWorkflowStepAction.new
    wsa.dmsf_workflow_step_assignment_id = 9
    wsa.action = DmsfWorkflowStepAction::ACTION_APPROVE
    wsa.author_id = @jsmith.id
    assert wsa.save
    # The workflow is finished
    assert @wf1.try_finish(@revision1, @wfsac1, @jsmith.id)
    @revision1.reload
    assert_equal DmsfWorkflow::STATE_APPROVED, @revision1.workflow
  end

  def test_try_finish_no
    # The forkflow is waiting for an approval
    assert_equal DmsfWorkflow::STATE_WAITING_FOR_APPROVAL, @revision1.workflow
    # The workflow is not finished
    assert_not @wf1.try_finish(@revision1, @wfsac1, @jsmith.id)
    @revision1.reload
    assert_equal DmsfWorkflow::STATE_WAITING_FOR_APPROVAL, @revision1.workflow
  end

  def test_participiants
    assert_equal @wf1.participiants.count, 2
  end

  def test_locked
    assert @wf3.locked?, "#{@wf2.name} status is #{@wf3.status}"
  end

  def test_active
    assert @wf1.active?, "#{@wf1.name} status is #{@wf1.status}"
  end

  def test_scope_active
    assert_equal DmsfWorkflow.count, (DmsfWorkflow.active.all.size + 1)
  end

  def test_scope_status
    assert_equal 1, DmsfWorkflow.status(DmsfWorkflow::STATUS_LOCKED).all.size
  end

  def test_copy_to
    wf = @wf1.copy_to(@project5, "#{@wf1.name}_copy")
    assert_equal wf.project_id, @project5.id
    assert_equal wf.name, "#{@wf1.name}_copy"
  end
end
