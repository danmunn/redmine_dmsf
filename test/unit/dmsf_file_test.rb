# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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
  fixtures :projects, :users, :email_addresses, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :roles, :members,
           :member_roles, :dmsf_locks, :issues, :dmsf_links

  def setup
    @admin = User.find_by_id 1
    @jsmith = User.find_by_id 2
    @project1 = Project.find_by_id 1
    @file1 = DmsfFile.find_by_id 1
    @file2 = DmsfFile.find_by_id 2
    @file3 = DmsfFile.find_by_id 3
    @file4 = DmsfFile.find_by_id 4
    @file5 = DmsfFile.find_by_id 5
    @file6 = DmsfFile.find_by_id 6
    @file7 = DmsfFile.find_by_id 7
    @file8 = DmsfFile.find_by_id 8
    @folder1 = DmsfFolder.find_by_id 1
    @issue1 = Issue.find_by_id 1
    User.current = nil
  end

  def test_truth
    assert_kind_of User, @admin
    assert_kind_of User, @jsmith
    assert_kind_of Project, @project1
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file2
    assert_kind_of DmsfFile, @file3
    assert_kind_of DmsfFile, @file4
    assert_kind_of DmsfFile, @file5
    assert_kind_of DmsfFile, @file6
    assert_kind_of DmsfFile, @file7
    assert_kind_of DmsfFile, @file8
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of Issue, @issue1
  end

  def test_project_file_count_differs_from_project_visibility_count
    assert_not_same(@project1.dmsf_files.count, @project1.dmsf_files.visible.count)
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
    @file1.lock!
    assert !@file1.locked_for_user?,
      "#{@file1.name} is locked for #{User.current.name}"
    @file1.unlock!
  end

  def test_file_locked_is_locked_for_user_who_didnt_lock
    User.current = @admin
    @file1.lock!
    User.current = @jsmith
    assert @file1.locked_for_user?,
      "#{@file1.name} is locked for #{User.current.name}"
    User.current = @admin
    @file1.unlock!
  end

  def test_file_with_no_locks_reported_unlocked
    assert !@file1.locked?
  end

  def test_delete_restore
    assert_equal 1, @file4.dmsf_file_revisions.visible.count
    assert_equal 2, @file4.referenced_links.visible.count
  end

  def test_delete
    User.current = @admin
    @file4.dmsf_folder.unlock!
    assert @file4.delete(false), @file4.errors.full_messages.to_sentence
    assert @file4.deleted?, "File #{@file4.name} is not deleted"
    assert_equal 0, @file4.dmsf_file_revisions.visible.count
    # Links should not be deleted
    assert_equal 2, @file4.referenced_links.visible.count
    @file4.dmsf_folder.lock!
  end

  def test_restore
    User.current = @admin
    @file4.dmsf_folder.unlock!
    assert @file4.delete(false), @file4.errors.full_messages.to_sentence
    @file4.restore
    assert !@file4.deleted?, "File #{@file4} hasn't been restored"
    assert_equal 1, @file4.dmsf_file_revisions.visible.count
    assert_equal 2, @file4.referenced_links.visible.count
    @file4.dmsf_folder.lock!
  end

  def test_destroy
    User.current = @admin
    @file4.dmsf_folder.unlock!
    assert_equal 1, @file4.dmsf_file_revisions.visible.count
    assert_equal 2, @file4.referenced_links.visible.count
    @file4.delete true
    assert_equal 0, @file4.dmsf_file_revisions.count
    assert_equal 0, @file4.referenced_links.count
    @file4.dmsf_folder.lock!
  end
  
  def test_copy_to_filename
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      new_file = @file1.copy_to_filename(@file1.project, nil, "new_file.txt")
      assert_not_equal new_file.id, @file1.id
      assert_nil new_file.dmsf_folder_id
      assert_nil @file1.dmsf_folder_id
      assert_not_equal new_file.name, @file1.name
      assert_equal new_file.dmsf_file_revisions.count, 1
    end
  end
  
  def test_copy_to
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      new_file = @file1.copy_to(@file1.project, @folder1)
      assert_not_equal new_file.id, @file1.id
      assert_not_equal @file1.dmsf_folder_id, @folder1.id
      assert_equal new_file.dmsf_folder_id, @folder1.id
      assert_equal new_file.name, @file1.name
      assert_equal new_file.dmsf_file_revisions.count, 1
    end
  end
  
  def test_save_and_destroy_with_cache
    Rails.cache.clear
    # save
    cache_key = @file5.propfind_cache_key
    RedmineDmsf::Webdav::Cache.write(cache_key, '')
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @file5.save
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    RedmineDmsf::Webdav::Cache.delete("#{cache_key}.invalid")
    # destroy
    RedmineDmsf::Webdav::Cache.write(cache_key, '')
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @file5.destroy
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    # save!
    cache_key = @file6.propfind_cache_key
    RedmineDmsf::Webdav::Cache.write(cache_key, '')
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @file6.save!
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    RedmineDmsf::Webdav::Cache.delete("#{cache_key}.invalid")
    # destroy!
    RedmineDmsf::Webdav::Cache.write(cache_key, '')
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @file6.destroy!
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
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
    assert_equal 'attachment', @file1.disposition
    assert_equal 'inline', @file7.disposition
    assert_equal 'inline', @file8.disposition
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

  def test_findn_file_by_name
    assert DmsfFile.find_file_by_name(@project1, nil, 'test.txt')
    assert_nil DmsfFile.find_file_by_name(@project1, nil, 'test.odt')
    assert DmsfFile.find_file_by_name(@issue1, nil, 'test.pdf')
    assert_nil DmsfFile.find_file_by_name(@issue1, nil, 'test.odt')
  end

  def test_to_csv
    columns = ['id', 'title']
    csv = @file1.to_csv(columns, 0)
    assert_equal 2, csv.size
  end

end