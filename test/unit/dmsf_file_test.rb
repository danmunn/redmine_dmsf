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

require File.expand_path('../../test_helper', __FILE__)

class DmsfFileTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :enabled_modules, :enumerations,
           :dmsf_locks

  test "file data is created" do
    assert_not_nil(dmsf_files(:dmsf_files_001))
  end

  test "project file count differs from project visibility count" do
    project = Project.find(1)
    assert_not_same(project.dmsf_files.count, project.dmsf_files.visible.count)
  end

  test "project DMSF file listing contains deleted items" do
    project = Project.find(1)
    found_deleted = false
    project.dmsf_files.each {|file|
      found_deleted = true if file.deleted
    }
    assert found_deleted, "Expected at least one deleted item in <all items>"
  end

  test "project DMSF file visible listing contains no deleted items" do
    project = Project.find(1)
    project.dmsf_files.visible.each {|file|
      assert !file.deleted, "File #{file.name} is deleted, this was unexpected"
    }
  end

  test "Known locked file responds as being locked" do
    file = dmsf_files(:dmsf_files_002)
    assert file.locked?
  end

  test "File with locked folder is reported as locked" do
    file = dmsf_files(:dmsf_files_004)
    assert file.locked?
  end

  test "File with folder up heirarchy (locked) is reported as locked" do 
    file = dmsf_files(:dmsf_files_005)
    assert file.locked?
  end

  test "File with folder up heirarchy (locked) is not locked for user id 1" do
    User.current = User.find(1)
    file = dmsf_files(:dmsf_files_005)

    assert file.locked?
    assert !file.locked_for_user?
  end

  test "File with no locks reported unlocked" do
    file = dmsf_files(:dmsf_files_001)
    assert !file.locked?
  end

end
