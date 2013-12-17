# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

require File.expand_path('../../test_helper.rb', __FILE__)

class DmsfFileTest < RedmineDmsf::Test::UnitTest
  attr_reader :lock
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :enabled_modules, :enumerations,
           :dmsf_locks

  def setup
    @lock = dmsf_locks(:dmsf_locks_001)
  end

  test "lock data is created" do
    assert_not_nil(lock)
  end

  test "lock_type is enumerable" do
    assert DmsfLock.respond_to?(:lock_types) #lock_types is a method created by as_enum
    assert DmsfLock.lock_types.is_a?(Hash)
  end

  test "lock_scope is enumerable" do
    assert DmsfLock.respond_to?(:lock_scopes) #lock_types is a method created by as_enum
    assert DmsfLock.lock_scopes.is_a?(Hash)
  end

  test "lock_type does not accept invalid values" do
    assert lock.lock_type = :type_write
    assert_raise ArgumentError do
      assert lock.lock_type = :write
    end
  end

  test "lock_type accepts a valid answer" do
    assert_nothing_raised ArgumentError do
      lock.lock_type = :type_write
      assert lock.lock_type == :type_write
    end
  end

  test "lock_scope does not accept invalid values" do
    assert lock.lock_scope = :scope_exclusive
    assert_raise ArgumentError do
      assert lock.lock_scope = :write
    end
  end

  test "lock_scope accepts a valid answer" do
    assert_nothing_raised ArgumentError do
      lock.lock_scope = :scope_shared
      assert lock.lock_scope == :scope_shared
    end
  end

  test "linked to either file or folder" do
    assert !(lock.file.nil? && lock.folder.nil?)
    assert !lock.file.nil? || !lock.folder.nil?
    if !lock.file.nil?
      assert lock.file.is_a?(DmsfFile)
    else
      assert lock.file.is_a?(DmsfFolder)
    end
  end

  test "locked folder reports un-locked child file as locked" do
    #folder id 2 is locked by fixture
    #files 4 and 5 are file resources within locked folder (declared by fixture)
    folder = dmsf_folders(:dmsf_folders_002)
    file = dmsf_files(:dmsf_files_004)

    assert folder.locked?, "Folder (2) should be locked by fixture"
    assert_equal 1, folder.lock.count #Check the folder lists 1 lock

    assert file.locked?, "File (4) sits within Folder(2) and should be locked"
    assert_equal 1, file.lock.count #Check the file lists 1 lock

    assert_equal 0, file.lock(false).count #Check the file does not list any entries for itself
  end

  test "locked folder cannot be unlocked by someone without rights (or anon)" do
    folder = dmsf_folders(:dmsf_folders_002)
    assert_no_difference ('folder.lock.count') do
      assert_raise DmsfLockError do
        folder.unlock!
      end
    end

    User.current = users(:users_002)
     assert_no_difference ('folder.lock.count') do
      assert_raise DmsfLockError do
        folder.unlock!
      end
    end
  end

  test "locked folder can be unlocked by permission :force_file_unlock" do
    User.current = users(:users_001)
    folder = dmsf_folders(:dmsf_folders_002)

    assert_difference('folder.lock.count', -1) do
      assert_nothing_raised do
        folder.unlock!
      end
    end

    User.current = users(:users_002)

    assert_difference('folder.lock.count') do
      assert_nothing_raised do
        folder.lock!
      end
    end

    User.current = users(:users_001)
    assert_difference('folder.lock.count', -1) do
      assert_nothing_raised do
        folder.unlock!
      end
    end


    #We need to re-establish locks for other test 
    folder.lock!
    User.current = nil

  end

end
