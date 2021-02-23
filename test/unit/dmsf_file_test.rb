# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFileTest < RedmineDmsf::Test::UnitTest

  fixtures :dmsf_locks, :issues, :dmsf_links, :dmsf_workflows, :dmsf_workflow_steps,
           :dmsf_workflow_step_assignments, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @issue1 = Issue.find 1
    @wf1 = DmsfWorkflow.find 1
    @wf2 = DmsfWorkflow.find 2
  end

  def test_project_file_count_differs_from_project_visibility_count
    assert_not_same @project1.dmsf_files.all.size, @project1.dmsf_files.visible.all.size
  end

  def test_project_dmsf_file_listing_contains_deleted_items
    assert @project1.dmsf_files.index{ |f| f.deleted? },
      'Expected at least one deleted item in <all items>'
  end

  def test_project_dmsf_file_visible_listing_contains_no_deleted_items
    assert @project1.dmsf_files.visible.index{ |f| f.deleted? }.nil?,
      'There is a deleted file, this was unexpected'
  end

  def test_known_locked_file_responds_as_being_locked
    assert @file2.locked?, "#{@file2.name} is not locked"
  end

  def test_file_with_locked_folder_is_reported_as_locked
    assert @file4.locked?, "#{@file4.name} is not locked"
  end

  def test_file_with_folder_up_heirarchy_locked_is_reported_as_locked
    assert @file5.locked?, "#{@file5.name} is not locked"
  end

  def test_file_locked_is_not_locked_for_user_who_locked
    User.current = @admin
    assert !@file2.locked_for_user?, "#{@file2.name} is locked for #{User.current}"
  end

  def test_file_locked_is_locked_for_user_who_didnt_lock
    User.current = @jsmith
    assert @file2.locked_for_user?, "#{@file1.name} is locked for #{User.current}"
  end

  def test_file_with_no_locks_reported_unlocked
    assert !@file1.locked?
  end

  def test_delete_restore
    assert_equal 1, @file4.dmsf_file_revisions.visible.all.size
    assert_equal 2, @file4.referenced_links.visible.all.size
  end

  def test_delete
    User.current = @admin
    @file4.dmsf_folder.unlock!
    assert @file4.delete(false), @file4.errors.full_messages.to_sentence
    assert @file4.deleted?, "File #{@file4.name} is not deleted"
    assert_equal 0, @file4.dmsf_file_revisions.visible.all.size
    # Links should not be deleted
    assert_equal 2, @file4.referenced_links.visible.all.size
  end

  def test_restore
    User.current = @admin
    @file4.dmsf_folder.unlock!
    assert @file4.delete(false), @file4.errors.full_messages.to_sentence
    @file4.restore
    assert !@file4.deleted?, "File #{@file4} hasn't been restored"
    assert_equal 1, @file4.dmsf_file_revisions.visible.all.size
    assert_equal 2, @file4.referenced_links.visible.all.size
  end

  def test_destroy
    User.current = @admin
    @file4.dmsf_folder.unlock!
    assert_equal 1, @file4.dmsf_file_revisions.visible.all.size
    assert_equal 2, @file4.referenced_links.visible.all.size
    @file4.delete true
    assert_equal 0, @file4.dmsf_file_revisions.all.size
    assert_equal 0, @file4.referenced_links.all.size
  end

  def test_copy_to_filename
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      new_file = @file1.copy_to_filename(@file1.project, nil, 'new_file.txt')
      assert_not_equal new_file.id, @file1.id
      assert_nil new_file.dmsf_folder_id
      assert_nil @file1.dmsf_folder_id
      assert_not_equal new_file.name, @file1.name
      assert_equal new_file.dmsf_file_revisions.all.size, 1
      assert_nil new_file.last_revision.workflow
      assert_nil new_file.last_revision.dmsf_workflow_id
      assert_nil new_file.last_revision.dmsf_workflow_assigned_by_user_id
      assert_nil new_file.last_revision.dmsf_workflow_assigned_at
      assert_nil new_file.last_revision.dmsf_workflow_started_by_user_id
      assert_nil new_file.last_revision.dmsf_workflow_started_at
    end
  end

  def test_copy_to_filename_with_global_workflow
    @file1.last_revision.set_workflow(@wf2.id, nil)
    @file1.last_revision.assign_workflow(@wf2.id)
    new_file = @file1.copy_to_filename(@project2, nil, 'new_file.txt')
    assert_equal DmsfWorkflow::STATE_ASSIGNED, new_file.last_revision.workflow
    assert_equal @wf2.id, new_file.last_revision.dmsf_workflow_id
    assert_equal User.current, new_file.last_revision.dmsf_workflow_assigned_by_user
    assert new_file.last_revision.dmsf_workflow_assigned_at
    assert_nil new_file.last_revision.dmsf_workflow_started_by_user_id
    assert_nil new_file.last_revision.dmsf_workflow_started_at
  end

  def test_copy_to_filename_with_workflow_to_the_same_project
    @file7.last_revision.set_workflow(@wf1.id, nil)
    @file7.last_revision.assign_workflow(@wf1.id)
    new_file = @file7.copy_to_filename(@project1, nil, 'new_file.txt')
    assert_equal DmsfWorkflow::STATE_ASSIGNED, new_file.last_revision.workflow
    assert_equal @wf1.id, new_file.last_revision.dmsf_workflow_id
    assert_equal User.current, new_file.last_revision.dmsf_workflow_assigned_by_user
    assert new_file.last_revision.dmsf_workflow_assigned_at
    assert_nil new_file.last_revision.dmsf_workflow_started_by_user_id
    assert_nil new_file.last_revision.dmsf_workflow_started_at
  end

  def test_copy_to_filename_with_workflow_to_other_project
    @file7.last_revision.set_workflow(@wf1.id, nil)
    @file7.last_revision.assign_workflow(@wf1.id)
    new_file = @file7.copy_to_filename(@project2, nil, 'new_file.txt')
    assert_nil new_file.last_revision.workflow
    assert_nil new_file.last_revision.dmsf_workflow_id
    assert_nil new_file.last_revision.dmsf_workflow_assigned_by_user_id
    assert_nil new_file.last_revision.dmsf_workflow_assigned_at
    assert_nil new_file.last_revision.dmsf_workflow_started_by_user_id
    assert_nil new_file.last_revision.dmsf_workflow_started_at
  end

  def test_copy_to
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      new_file = @file1.copy_to(@file1.project, @folder1)
      assert_not_equal new_file.id, @file1.id
      assert_not_equal @file1.dmsf_folder_id, @folder1.id
      assert_equal new_file.dmsf_folder_id, @folder1.id
      assert_equal new_file.name, @file1.name
      assert_equal new_file.dmsf_file_revisions.all.size, 1
    end
  end

  def test_project_project
    project = @file1.project
    assert_not_nil project
    assert project.is_a?(Project)
  end

  def test_project_issue
    project = @file7.project
    assert_not_nil project
    assert project.is_a?(Project)
  end

  def test_disposition
    # Text
    assert_equal 'attachment', @file1.disposition
    # Image
    assert_equal 'inline', @file7.disposition
    # PDF
    assert_equal 'inline', @file8.disposition
    # Video
    @file1.last_revision.disk_filename = 'test.mp4'
    assert_equal 'inline', @file1.disposition
    # HTML
    @file1.last_revision.disk_filename = 'test.html'
    assert_equal 'inline', @file1.disposition
  end

  def test_image
    assert !@file1.image?
    assert @file7.image?
    assert !@file8.image?
  end

  def test_text
    assert @file1.text?
    assert !@file7.text?
    assert !@file8.text?
  end

  def test_pdf
    assert !@file1.pdf?
    assert !@file7.pdf?
    assert @file8.pdf?
  end

  def test_video
    assert !@file1.video?
    @file1.last_revision.disk_filename = 'test.mp4'
    assert @file1.video?
  end

  def test_html
    assert !@file1.html?
    @file1.last_revision.disk_filename = 'test.html'
    assert @file1.html?
  end

  def test_findn_file_by_name
    assert DmsfFile.find_file_by_name(@project1, nil, 'test.txt')
    assert_nil DmsfFile.find_file_by_name(@project1, nil, 'test.odt')
    assert DmsfFile.find_file_by_name(@issue1, nil, 'test.pdf')
    assert_nil DmsfFile.find_file_by_name(@issue1, nil, 'test.odt')
  end

  def test_storage_path
    with_settings plugin_redmine_dmsf: {'dmsf_storage_directory' => 'files/dmsf'} do
      sp = DmsfFile.storage_path
      assert_kind_of Pathname, sp
      assert_equal Rails.root.join(Setting.plugin_redmine_dmsf['dmsf_storage_directory']).to_s, sp.to_s
    end
  end

  def test_owner
    assert @file1.owner?(@file1.last_revision.user)
    assert !@file1.owner?(@jsmith)
    @file1.last_revision.user = @jsmith
    assert @file1.owner?(@jsmith)
  end

  def test_involved
    assert @file1.involved?(@file1.last_revision.user)
    assert !@file1.involved?(@jsmith)
    @file1.dmsf_file_revisions[1].user = @jsmith
    assert @file1.involved?(@jsmith)
  end

  def test_assigned
    assert !@file1.assigned?(@admin)
    assert !@file1.assigned?(@jsmith)
    @file7.last_revision.set_workflow @wf1.id, nil
    @file7.last_revision.assign_workflow @wf1.id
    assert @file7.assigned?(@admin)
    assert @file7.assigned?(@jsmith)
  end

  def test_locked_by
    # Locked file
    assert_equal @admin.name, @file2.locked_by
    # Unlocked file
    assert_equal '', @file1.locked_by
  end

end