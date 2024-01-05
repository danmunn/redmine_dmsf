# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

# Lock tests
class DmsfLockTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_locks, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @lock = DmsfLock.find 1
  end

  def test_lock_type_is_enumerable
    assert DmsfLock.respond_to?(:lock_types), "DmsfLock class hasn't got lock_types method"
    assert DmsfLock.lock_types.is_a?(SimpleEnum::Enum),  'DmsfLock class is not enumerable'
  end

  def test_lock_scope_is_enumerable
    assert DmsfLock.respond_to?(:lock_scopes), "DmsfLock class hasn't got lock_scopes method"
    assert DmsfLock.lock_scopes.is_a?(SimpleEnum::Enum), 'DmsfLock class is not enumerable'
  end

  def test_linked_to_either_file_or_folder
    assert_not_nil @lock.dmsf_file || @lock.dmsf_folder
    if @lock.dmsf_file
      assert_kind_of DmsfFile, @lock.dmsf_file
    else
      assert_kind_of DmsfFolder, @lock.dmsf_folder
    end
  end

  def test_locked_folder_reports_un_locked_child_file_as_locked
    assert @folder2.locked?, "Folder #{@folder2.title} should be locked by fixture"
    assert_equal 1, @folder2.lock.count # Check the folder lists 1 lock
    assert @file4.locked?, "File #{@file4.name} sits within #{@folder2.title} and should be locked"
    assert_equal 1, @file4.lock.count # Check the file lists 1 lock
    assert_equal 0, @file4.lock(tree: false).count # Check the file does not list any entries for itself
  end

  def test_locked_folder_cannot_be_unlocked_by_someone_without_rights_or_anon
    User.current = @admin
    @folder7.lock!
    User.current = nil
    assert_no_difference('@folder7.lock.count') do
      assert_raise RedmineDmsf::Errors::DmsfLockError do
        @folder7.unlock!
      end
    end
    User.current = @jsmith
    assert_no_difference('@folder7.lock.count') do
      assert_raise RedmineDmsf::Errors::DmsfLockError do
        @folder7.unlock!
      end
    end
  end

  def test_locked_folder_can_be_unlocked_by_permission
    User.current = @admin
    assert_difference('@folder2.lock.count', -1) do
      assert_nothing_raised do
        @folder2.unlock!
      end
    end
    User.current = @jsmith
    assert_difference('@folder2.lock.count') do
      assert_nothing_raised do
        @folder2.lock!
      end
    end
    User.current = @admin
    assert_difference('@folder2.lock.count', -1) do
      assert_nothing_raised do
        @folder2.unlock!
      end
    end
    @folder2.lock!
  end

  def test_expired
    User.current = @jsmith
    lock = DmsfLock.new
    assert_not lock.expired?
    lock.expires_at = Time.current
    assert lock.expired?
    lock.expires_at = 1.hour.from_now
    assert_not lock.expired?
  end
end
