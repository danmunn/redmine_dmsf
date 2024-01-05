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

# Workflow step
class DmsfWorkflowStepTest < RedmineDmsf::Test::UnitTest
  include Redmine::I18n

  fixtures :dmsf_workflows, :dmsf_workflow_steps, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    @wfs1 = DmsfWorkflowStep.find 1
    @wfs2 = DmsfWorkflowStep.find 2
    @wfs5 = DmsfWorkflowStep.find 5
    @revision1 = DmsfFileRevision.find 1
    @revision2 = DmsfFileRevision.find 2
    @wf2 = DmsfWorkflow.find 2
  end

  def test_create
    wfs = DmsfWorkflowStep.new
    wfs.dmsf_workflow_id = 1
    wfs.step = 2
    wfs.name = '2nd step'
    wfs.user_id = 3
    wfs.operator = 1
    assert wfs.save, wfs.errors.full_messages.to_sentence
  end

  def test_update
    @wfs1.dmsf_workflow_id = 2
    @wfs1.step = 2
    @wfs1.name = '2nd step'
    @wfs1.user_id = 2
    @wfs1.operator = 2
    assert @wfs1.save, @wfs1.errors.full_messages.to_sentence
    @wfs1.reload
    assert_equal 2, @wfs1.dmsf_workflow_id
    assert_equal 2, @wfs1.step
    assert_equal '2nd step', @wfs1.name
    assert_equal 2, @wfs1.user_id
    assert_equal 2, @wfs1.operator
  end

  def test_validate_step_presence
    @wfs1.step = nil
    assert_not @wfs1.save
    assert @wfs1.errors.any?
  end

  def test_validate_operator_presence
    @wfs1.operator = nil
    assert_not @wfs1.save
    assert @wfs1.errors.any?
  end

  def test_validate_user_id_uniqueness
    @wfs2.user_id = @wfs1.user_id
    @wfs2.dmsf_workflow_id = @wfs1.dmsf_workflow_id
    @wfs2.step = @wfs1.step
    assert_not @wfs2.save
    assert @wfs2.errors.any?
  end

  def test_validate_name_length
    @wfs1.name = 'a' * 31
    assert_not @wfs1.save
    assert_equal 1, @wfs1.errors.count
  end

  def test_destroy
    assert_not DmsfWorkflowStepAssignment.where(dmsf_workflow_step_id: @wfs2.id).empty?
    @wfs2.destroy
    assert_nil DmsfWorkflowStep.find_by(id: 2)
    assert_equal DmsfWorkflowStepAssignment.where(dmsf_workflow_step_id: @wfs2.id).all.size, 0
  end

  def test_soperator
    assert_equal @wfs1.soperator, l(:dmsf_or)
  end

  def test_user
    assert_equal @wfs1.user, User.find_by(id: @wfs1.user_id)
  end

  def test_assign
    @wfs5.assign(@revision2.id)
    assert DmsfWorkflowStepAssignment.exists?(dmsf_workflow_step_id: @wfs5.id, dmsf_file_revision_id: @revision2.id)
  end

  def test_copy_to
    wfs = @wfs1.copy_to(@wf2)
    assert_equal wfs.dmsf_workflow_id, @wf2.id
    assert_equal wfs.step, @wfs1.step
    assert_equal wfs.name, @wfs1.name
    assert_equal wfs.user_id, @wfs1.user_id
    assert_equal wfs.operator, @wfs1.operator
  end
end
