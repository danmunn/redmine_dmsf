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

require File.expand_path('../../test_helper', __FILE__)

# Folder tests
class DmsfFolderTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_folder_permissions, :dmsf_locks, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :dmsf_links

  def setup
    super
    @link2 = DmsfLink.find 2
  end

  def test_visibility
    # The role has got permissions
    User.current = @jsmith
    assert_equal 7, DmsfFolder.where(project_id: @project1.id).all.size
    assert_equal 5, DmsfFolder.visible.where(project_id: @project1.id).all.size
    # The user has got permissions
    User.current = @dlopper
    # Hasn't got permissions for @folder7
    @folder7.dmsf_folder_permissions.where(object_type: 'User').delete_all
    assert_equal 4, DmsfFolder.visible.where(project_id: @project1.id).all.size
    # Anonymous user
    User.current = User.anonymous
    @project1.add_default_member User.anonymous
    assert_equal 5, DmsfFolder.visible.where(project_id: @project1.id).all.size
  end

  def test_visible
    assert @folder1.visible?
    assert @folder1.visible?(@jsmith)
    @folder1.deleted = DmsfFolder::STATUS_DELETED
    class << @folder1
      attr_accessor :type
    end
    @folder1.type = 'folder'
    assert_not @folder1.visible?
  end

  def test_permissions
    User.current = @dlopper
    assert DmsfFolder.permissions?(@folder7)
    @folder7.dmsf_folder_permissions.where(object_type: 'User').delete_all
    @folder7.reload
    assert_not DmsfFolder.permissions?(@folder7)
  end

  def test_permissions_to_system_folder
    User.current = @jsmith
    assert DmsfFolder.permissions?(@folder8)
  end

  def test_delete
    assert @folder6.delete(commit: false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted?, "Folder #{@folder6} hasn't been deleted"
  end

  def test_delete_recursively
    assert @folder1.delete(commit: false), @folder1.errors.full_messages.to_sentence
    # First&second level
    [@folder1, @folder2].each do |folder|
      assert_equal folder.dmsf_folders.all.size, folder.dmsf_folders.collect(&:deleted?).size
      assert_equal folder.dmsf_files.all.size, folder.dmsf_files.collect(&:deleted?).size
      assert_equal folder.dmsf_links.all.size, folder.dmsf_links.collect(&:deleted?).size
    end
  end

  def test_restore
    assert @folder6.delete(commit: false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted?, "Folder #{@folder6} hasn't been deleted"
    assert @folder6.restore, @folder6.errors.full_messages.to_sentence
    assert_not @folder6.deleted?, "Folder #{@folder6} hasn't been restored"
  end

  def test_restore_recursively
    # Delete
    assert @folder1.delete(commit: false), @folder1.errors.full_messages.to_sentence
    # Restore
    assert @folder1.restore, @folder1.errors.full_messages.to_sentence
    assert_not @folder1.deleted?, "Folder #{@folder1} hasn't been restored"
    # First level
    assert_not @folder2.deleted?, "Folder #{@folder2} hasn't been restored"
    assert_not @link2.deleted?, "Link #{@link2} hasn't been restored"
    # Second level
    assert_not @file4.deleted?, "File #{@file4} hasn't been restored"
  end

  def test_destroy
    folder6_id = @folder6.id
    @folder6.delete commit: true
    assert_nil DmsfFolder.find_by(id: folder6_id)
  end

  def test_destroy_recursively
    folder1_id = @folder1.id
    folder2_id = @folder2.id
    link2_id = @link2.id
    file4_id = @file4.id
    @folder1.delete commit: true
    assert_nil DmsfFolder.find_by(id: folder1_id)
    # First level
    assert_nil DmsfFolder.find_by(id: folder2_id)
    assert_nil DmsfLink.find_by(id: link2_id)
    # Second level
    assert_nil DmsfFile.find_by(id: file4_id)
  end

  def test_is_column_on_default
    DmsfFolder::DEFAULT_COLUMNS.each do |column|
      assert DmsfFolder.column_on?(column), "The column #{column} is not on?"
    end
  end

  def test_is_column_on_available
    (DmsfFolder::AVAILABLE_COLUMNS - DmsfFolder::DEFAULT_COLUMNS).each do |column|
      assert_not DmsfFolder.column_on?(column), "The column #{column} is on?"
    end
  end

  def test_get_column_position_default
    # 0 - checkbox
    assert_nil DmsfFolder.get_column_position('checkbox'), "The column 'checkbox' is on?"
    # 1 - id
    assert_nil DmsfFolder.get_column_position('id'), "The column 'id' is on?"
    # 2 - title
    assert_equal DmsfFolder.get_column_position('title'), 1, "The expected position of the 'title' column is 1"
    # 3 - size
    assert_equal DmsfFolder.get_column_position('size'), 2, "The expected position of the 'size' column is 2"
    # 4 - modified
    assert_equal DmsfFolder.get_column_position('modified'), 3, "The expected position of the 'modified' column is 3"
    # 5 - version
    assert_equal DmsfFolder.get_column_position('version'), 4, "The expected position of the 'version' column is 4"
    # 6 - workflow
    assert_equal DmsfFolder.get_column_position('workflow'), 5, "The expected position of the 'workflow' column is 5"
    # 7 - author
    assert_equal DmsfFolder.get_column_position('author'), 6, "The expected position of the 'workflow' column is 6"
    # 8 - custom fields
    assert_nil DmsfFolder.get_column_position('Tag'), "The column 'Tag' is on?"
    # 9 - commands
    assert_equal DmsfFolder.get_column_position('commands'), 7, "The expected position of the 'commands' column is 7"
    # 10 - position
    assert_equal DmsfFolder.get_column_position('position'), 8, "The expected position of the 'position' column is 8"
    # 11 - size
    assert_equal DmsfFolder.get_column_position('size_calculated'), 9,
                 "The expected position of the 'size_calculated' column is 9"
    # 12 - modified
    assert_equal DmsfFolder.get_column_position('modified_calculated'), 10,
                 "The expected position of the 'modified_calculated' column is 10"
    # 13 - version
    assert_equal DmsfFolder.get_column_position('version_calculated'), 11,
                 "The expected position of the 'version_calculated' column is 11"
  end

  def test_directory_tree
    User.current = @admin
    @folder7.lock!
    User.current = @jsmith
    assert @folder7.locked_for_user?
    tree = DmsfFolder.directory_tree(@project1)
    assert tree
    # [["Documents", nil],
    #  ["...folder1", 1],
    #  ["......folder2", 2]
    #  [".........folder5", 5],
    #  ["...folder6", 6]]
    #  ["...folder7", 7] - locked
    assert tree.to_s.include?('...folder1'), "'...folder1' string in the folder tree expected."
    assert_not tree.to_s.include?('...folder7'), "'...folder7' string in the folder tree not expected."
  end

  def test_directory_tree_id
    User.current = @admin
    @folder7.lock!
    User.current = @jsmith
    assert @folder7.locked_for_user?
    tree = DmsfFolder.directory_tree(@project1.id)
    assert tree
    # [["Documents", nil],
    #  ["...folder1", 1],
    #  ["......folder2", 2]
    #  [".........folder5", 5],
    #  ["...folder6", 6]]
    #  ["...folder7", 7] - locked
    assert tree.to_s.include?('...folder1'), "'...folder1' string in the folder tree expected."
    assert_not tree.to_s.include?('...folder7'), "'...folder7' string in the folder tree not expected."
  end

  def test_folder_tree
    User.current = @admin
    tree = @folder1.folder_tree
    assert tree
    # [["folder1", 1],
    #  ["...folder2", 2] - locked for admin
    assert tree.to_s.include?('folder1'), "'folder1' string in the folder tree expected."
    assert_not tree.to_s.include?('...folder2'), "'...folder2' string in the folder tree not expected."
  end

  def test_get_valid_title
    assert_equal '1052-6024 . U_CPLD_5M240Z_SMT_MBGA100_1.8V_-40',
                 DmsfFolder.get_valid_title('1052-6024 : U_CPLD_5M240Z_SMT_MBGA100_1.8V_-40...')
    assert_equal 'test', DmsfFolder.get_valid_title("test#{DmsfFolder::INVALID_CHARACTERS}")
  end

  def test_permission_for_role
    checked = @folder7.permission_for_role(@manager_role)
    assert checked
  end

  def test_permissions_users
    users = @folder7.permissions_users
    assert_equal 1, users.size
  end

  def test_move_to
    User.current = @jsmith
    assert @folder1.move_to(@project2, nil)
    assert_equal @project2, @folder1.project
    @folder1.dmsf_folders.each do |d|
      assert_equal @project2.identifier, d.project.identifier
    end
    @folder1.dmsf_files.each do |f|
      assert_equal @project2, f.project
    end
    @folder1.dmsf_links.each do |l|
      assert_equal @project2, l.project
    end
  end

  def test_copy_to
    assert @folder1.copy_to(@project2, nil)
    assert DmsfFolder.find_by(project_id: @project2.id, title: @folder1.title)
  end

  def test_move_to_author
    assert_equal @admin.id, @folder1.user_id
    User.current = @jsmith
    assert @folder1.move_to(@folder6.project, @folder6)
    assert_equal @admin.id, @folder1.user_id, "Author mustn't be updated when moving"
  end

  def test_copy_to_author
    assert_equal @admin.id, @folder1.user_id
    User.current = @jsmith
    f = @folder1.copy_to(@folder6.project, @folder6)
    assert f
    assert_equal @jsmith.id, f.user_id, 'Author must be updated when copying'
  end

  def test_valid_parent
    @folder2.dmsf_folder = @folder1
    assert @folder2.save
  end

  def test_valid_parent_nil
    @folder2.dmsf_folder = nil
    assert @folder2.save
  end

  def test_valid_parent_loop
    @folder1.dmsf_folder = @folder2
    # @folder2 is under @folder1 => loop!
    assert_not @folder1.save
  end

  def test_empty
    assert_not @folder1.empty?
    assert @folder6.empty?
  end

  def test_watchable
    @folder1.add_watcher @jsmith
    assert @folder1.watched_by?(@jsmith)
  end

  def test_update_from_params_with_invalid_string_sequence
    invalid_string_sequence = "Invalid sequence\x81"
    params = { dmsf_folder: { title: invalid_string_sequence, description: invalid_string_sequence } }
    assert @folder1.update_from_params(params)
    assert_equal invalid_string_sequence.scrub, @folder1.title
    assert_equal invalid_string_sequence.scrub, @folder1.description
  end

  def test_issystem
    assert DmsfFolder.where(id: @folder8.id).issystem.exists?
    @folder8.deleted = DmsfFolder::STATUS_DELETED
    assert @folder8.save
    assert_not DmsfFolder.where(id: @folder8.id).issystem.exists?
  end

  def test_any_child
    # folder1
    ## folder 2
    # folder6
    assert_not @folder1.any_child?(@folder6)
    assert @folder1.any_child?(@folder2)
  end

  def delete_system_folder
    # System folders
    assert DmsfFolder.where(id: [8, 9]).exist?
    @file_link7.destroy
    @dmsf_file11.destroy
    # System folders are empty and should have been deleted
    assert_not DmsfFolder.where(id: [8, 9]).exist?
  end
end
