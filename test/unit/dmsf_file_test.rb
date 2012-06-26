require File.dirname(__FILE__) + '/../test_helper'

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
