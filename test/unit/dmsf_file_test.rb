# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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
  fixtures :projects, :users, :email_addresses, :dmsf_folders, :dmsf_files, 
    :dmsf_file_revisions, :roles, :members, :member_roles, :dmsf_locks, 
    :dmsf_links
         
  def setup
    @admin = User.find_by_id 1
    @jsmith = User.find_by_id 2    
    @project1 = Project.find_by_id 1
    @file1 = DmsfFile.find_by_id 1
    @file2 = DmsfFile.find_by_id 2
    @file3 = DmsfFile.find_by_id 3
    @file4 = DmsfFile.find_by_id 4
    @file5 = DmsfFile.find_by_id 5    
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
  end    

  def test_project_file_count_differs_from_project_visibility_count
    assert_not_same(@project1.dmsf_files.count, @project1.dmsf_files.visible.count)
  end

  def test_project_dmsf_file_listing_contains_deleted_items        
    assert @project1.dmsf_files.index{ |f| f.deleted }, 
      'Expected at least one deleted item in <all items>'    
  end

  def test_project_dmsf_file_visible_listing_contains_no_deleted_items    
    assert @project1.dmsf_files.visible.index{ |f| f.deleted }.nil?, 
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
    assert_equal 1, @file4.revisions.visible.count
    assert_equal 2, @file4.referenced_links.visible.count
  end
  
  def test_delete
    User.current = @admin
    @file4.folder.unlock!
    assert @file4.delete(false), @file4.errors.full_messages.to_sentence
    assert @file4.deleted, "File #{@file4.name} is not deleted"
    assert_equal 0, @file4.revisions.visible.count
    assert_equal 0, @file4.referenced_links.visible.count
    @file4.folder.lock!
  end
    
  def test_restore
    User.current = @admin
    @file4.folder.unlock!
    assert @file4.delete(false), @file4.errors.full_messages.to_sentence
    @file4.restore        
    assert !@file4.deleted, "File #{@file4} hasn't been restored"
    assert_equal 1, @file4.revisions.visible.count
    assert_equal 2, @file4.referenced_links.visible.count
    @file4.folder.lock!
  end
  
  def test_destroy    
    User.current = @admin
    @file4.folder.unlock!
    assert_equal 1, @file4.revisions.visible.count
    assert_equal 2, @file4.referenced_links.visible.count
    @file4.delete true                
    assert_equal 0, @file4.revisions.count
    assert_equal 0, @file4.referenced_links.count
    @file4.folder.lock!
  end

end