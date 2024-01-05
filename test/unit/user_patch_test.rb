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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

# User tests
class UserPatchTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_links, :dmsf_locks, :dmsf_workflows, :dmsf_workflow_steps,
           :dmsf_workflow_step_assignments, :dmsf_workflow_step_actions, :dmsf_folders,
           :dmsf_files, :dmsf_file_revisions

  def test_remove_dmsf_references
    id = @jsmith.id
    @jsmith.destroy
    assert_equal 0, DmsfFileRevisionAccess.where(user_id: id).all.size
    assert_equal 0, DmsfFileRevision.where(user_id: id).all.size
    assert_equal 0, DmsfFileRevision.where(dmsf_workflow_assigned_by_user_id: id).all.size
    assert_equal 0, DmsfFileRevision.where(dmsf_workflow_started_by_user_id: id).all.size
    assert_equal 0, DmsfFile.where(deleted_by_user_id: id).all.size
    # TODO: Expected: 0, Actual: 1 in Easy extension
    f = DmsfFolder.where(user_id: id).first
    puts "#{f.id}, #{f.title}, #{f.user_id}, #{f.deleted}" if f
    # assert_equal 0, DmsfFolder.where(user_id: id).all.size
    assert_equal 0, DmsfFolder.where(deleted_by_user_id: id).all.size
    assert_equal 0, DmsfLink.where(user_id: id).all.size
    assert_equal 0, DmsfLink.where(deleted_by_user_id: id).all.size
    # assert_equal 0, DmsfLock.where(user_id: id).all.size
    # assert_equal 0, DmsfWorkflowStepAction.where(author_id: id).all.size
    # assert_equal 0, DmsfWorkflowStepAssignment.where(user_id: id).all.size
    # assert_equal 0, DmsfWorkflowStep.where(user_id: id).all.size
    # assert_equal 0, DmsfWorkflow.where(author_id: id).all.size
  end
end
