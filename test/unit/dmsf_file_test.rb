# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :dmsf_locks, :dmsf_links
         
  def setup
    @user1 = User.find_by_id 1
    @project1 = Project.find_by_id 1
    @file1 = DmsfFile.find_by_id 1
    @file2 = DmsfFile.find_by_id 2
    @file3 = DmsfFile.find_by_id 3
    @file4 = DmsfFile.find_by_id 4
    @file5 = DmsfFile.find_by_id 5
  end
  
  def test_truth
    assert_kind_of User, @user1
    assert_kind_of Project, @project1
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file2
    assert_kind_of DmsfFile, @file3
    assert_kind_of DmsfFile, @file4
    assert_kind_of DmsfFile, @file5
  end    

  test "project file count differs from project visibility count" do    
    assert_not_same(@project1.dmsf_files.count, @project1.dmsf_files.visible.count)
  end

  test "project DMSF file listing contains deleted items" do    
    found_deleted = false
    @project1.dmsf_files.each {|file|
      found_deleted = true if file.deleted
    }
    assert found_deleted, "Expected at least one deleted item in <all items>"
  end

  test "project DMSF file visible listing contains no deleted items" do    
    @project1.dmsf_files.visible.each {|file|
      assert !file.deleted, "File #{file.name} is deleted, this was unexpected"
    }
  end

  test "Known locked file responds as being locked" do    
    assert @file2.locked?
  end

  test "File with locked folder is reported as locked" do    
    assert @file4.locked?
  end

  test "File with folder up heirarchy (locked) is reported as locked" do    
    assert @file5.locked?
  end

  test "File with folder up heirarchy (locked) is not locked for user id 1" do
    User.current = @user1    
    assert @file5.locked?
    assert !@file5.locked_for_user?
  end

  test "File with no locks reported unlocked" do    
    assert !@file1.locked?
  end
  
  def test_delete_restore         
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 1, @file4.revisions.visible.count
    #assert_equal 2, @file4.referenced_links.visible.count
    
    # Delete
    @file4.delete false    
    assert @file4.deleted
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 0, @file4.revisions.visible.count
    #assert_equal 0, @file4.referenced_links.visible.count
    
    # Restore
    @file4.restore    
    assert !@file4.deleted
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 1, @file4.revisions.visible.count
    #assert_equal 2, @file4.referenced_links.visible.count
  end
  
  def test_destroy
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 1, @file4.revisions.visible.count
    #assert_equal 2, @file4.referenced_links.visible.count
    @file4.delete true    
    assert_nil DmsfFile.find_by_id(@file4.id)
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 0, @file4.revisions.count
    #assert_equal 0, @file4.referenced_links.count
  end

end