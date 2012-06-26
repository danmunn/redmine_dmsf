require File.dirname(__FILE__) + '/../test_helper'

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
  

end
