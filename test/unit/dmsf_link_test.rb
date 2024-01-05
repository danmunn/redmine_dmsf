# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Link tests
class DmsfLinksTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_links, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_create_folder_link
    folder_link = DmsfLink.new
    folder_link.target_project_id = @project1.id
    folder_link.target_id = @folder1.id
    folder_link.target_type = DmsfFolder.model_name.to_s
    folder_link.name = 'folder1_link2'
    folder_link.project_id = @project1.id
    folder_link.created_at = DateTime.current
    folder_link.updated_at = DateTime.current
    assert folder_link.save, folder_link.errors.full_messages.to_sentence
  end

  def test_create_file_link
    file_link = DmsfLink.new
    file_link.target_project_id = @project1.id
    file_link.target_id = @file1.id
    file_link.target_type = DmsfFile.model_name.to_s
    file_link.name = 'file1_link2'
    file_link.project_id = @project1.id
    file_link.created_at = DateTime.current
    file_link.updated_at = DateTime.current
    assert file_link.save, file_link.errors.full_messages.to_sentence
  end

  def test_create_external_link
    external_link = DmsfLink.new
    external_link.target_project_id = @project1.id
    external_link.external_url = 'http://www.redmine.org/plugins/dmsf'
    external_link.target_type = 'DmsfUrl'
    external_link.name = 'DMSF plugin'
    external_link.project_id = @project1.id
    external_link.created_at = DateTime.current
    external_link.updated_at = DateTime.current
    assert external_link.save, external_link.errors.full_messages.to_sentence
  end

  def test_validate_name_length
    @folder_link1.name = ('a' * 256)
    assert_not @folder_link1.save, "Folder link #{@folder_link1.name} should have not been saved"
    assert_equal 1, @folder_link1.errors.size
  end

  def test_validate_name_presence
    @folder_link1.name = ''
    assert_not @folder_link1.save, "Folder link #{@folder_link1.name} should have not been saved"
    assert_equal 1, @folder_link1.errors.size
  end

  def test_validate_external_url_length
    @file_link2.target_type = 'DmsfUrl'
    @file_link2.external_url = "https://localhost/#{'a' * 256}"
    assert_not @file_link2.save, "External URL link #{@file_link2.name} should have not been saved"
    assert_equal 1, @file_link2.errors.size
  end

  def test_validate_external_url_presence
    @file_link2.target_type = 'DmsfUrl'
    @file_link2.external_url = ''
    assert_not @file_link2.save, "External URL link #{@file_link2.name} should have not been saved"
    assert_equal 1, @file_link2.errors.size
  end

  def test_validate_external_url_invalid
    @file_link2.target_type = 'DmsfUrl'
    @file_link2.external_url = 'htt ps://abc.xyz'
    assert_not @file_link2.save, "External URL link #{@file_link2.name} should have not been saved"
    assert_equal 1, @file_link2.errors.size
  end

  def test_validate_external_url_valid
    @file_link2.target_type = 'DmsfUrl'
    @file_link2.external_url = 'https://www.google.com/search?q=寿司'
    assert @file_link2.save
  end

  def test_belongs_to_project
    @project1.destroy
    assert_nil DmsfLink.find_by(id: 1)
    assert_nil DmsfLink.find_by(id: 2)
  end

  def test_belongs_to_dmsf_folder
    @folder1.destroy
    assert_nil DmsfLink.find_by(id: 1)
    assert_nil DmsfLink.find_by(id: 2)
  end

  def test_target_folder_id
    assert_equal 2, @file_link2.target_folder_id
    assert_equal 1, @folder_link1.target_folder_id
  end

  def test_target_folder
    assert_equal @folder2, @file_link2.target_folder
    assert_equal @folder1, @folder_link1.target_folder
  end

  def test_target_file_id
    assert_equal 4, @file_link2.target_file_id
    assert_nil @folder_link1.target_file
  end

  def test_target_file
    assert_equal @file4, @file_link2.target_file
    assert_nil @folder_link1.target_file
  end

  def test_target_project
    assert_equal @project1, @file_link2.target_project
    assert_equal @project1, @folder_link1.target_project
  end

  def test_folder
    assert_equal @folder1, @file_link2.dmsf_folder
    assert_nil @folder_link1.dmsf_folder
  end

  def test_title
    assert_equal @file_link2.name, @file_link2.title
    assert_equal @folder_link1.name, @folder_link1.title
  end

  def test_find_link_by_file_name
    file_link = DmsfLink.find_link_by_file_name(@file_link2.project, @file_link2.dmsf_folder,
                                                @file_link2.target_file.name)
    assert file_link, 'File link not found by its name'
  end

  def test_path
    assert_equal 'folder1/folder2/test4.txt', @file_link2.path
    assert_equal 'folder1', @folder_link1.path
  end

  def test_file_kink_copy_to
    file_link_copy = @file_link2.copy_to @folder2.project, @folder2
    assert_not_nil file_link_copy, 'File link copying failed'
    assert_equal file_link_copy.target_project_id, @file_link2.target_project_id
    assert_equal file_link_copy.target_id, @file_link2.target_id
    assert_equal file_link_copy.target_type, @file_link2.target_type
    assert_equal file_link_copy.name, @file_link2.name
    assert_equal file_link_copy.project_id, @folder2.project.id
    assert_equal file_link_copy.dmsf_folder_id, @folder2.id
  end

  def test_folder_link_copy_to
    folder_link_copy = @folder_link1.copy_to @folder2.project, @folder2
    assert_not_nil folder_link_copy, 'Folder link copying failed'
    assert_equal folder_link_copy.target_project_id, @folder_link1.target_project_id
    assert_equal folder_link_copy.target_id, @folder_link1.target_id
    assert_equal folder_link_copy.target_type, @folder_link1.target_type
    assert_equal folder_link_copy.name, @folder_link1.name
    assert_equal folder_link_copy.project_id, @folder2.project.id
    assert_equal folder_link_copy.dmsf_folder_id, @folder2.id
  end

  def test_move_to_author
    assert_equal @admin.id, @file_link2.user_id
    User.current = @jsmith
    assert @file_link2.move_to(@project1, @folder1)
    assert_equal @admin.id, @file_link2.user_id, "Author mustn't be updated when moving"
  end

  def test_copy_to_author
    assert_equal @admin.id, @file_link2.user_id
    User.current = @jsmith
    l = @file_link2.copy_to(@project1, @folder1)
    assert l
    assert_equal @jsmith.id, l.user_id, 'Author must be updated when copying'
  end

  def test_delete_file_link
    assert @file_link2.delete(commit: false), @file_link2.errors.full_messages.to_sentence
    assert @file_link2.deleted?, "File link hasn't been deleted"
  end

  def test_restore_file_link
    assert @file_link2.delete(commit: false), @file_link2.errors.full_messages.to_sentence
    assert @file_link2.deleted?, "File link hasn't been deleted"
    assert @file_link2.restore, @file_link2.errors.full_messages.to_sentence
    assert_not @file_link2.deleted?, "File link hasn't been restored"
  end

  def test_delete_folder_link
    assert @folder_link1.delete(commit: false), @folder_link1.errors.full_messages.to_sentence
    assert @folder_link1.deleted?, "Folder link hasn't been deleted"
  end

  def test_restore_folder_link
    assert @folder_link1.delete(commit: false), @folder_link1.errors.full_messages.to_sentence
    assert @folder_link1.deleted?, "Folder link hasn't been deleted"
    assert @folder_link1.restore, @folder_link1.errors.full_messages.to_sentence
    assert_not @folder_link1.deleted?, "Folder link hasn't been restored"
  end

  def test_destroy_file_link
    assert @file_link2.delete(commit: true), @file_link2.errors.full_messages.to_sentence
    assert_nil DmsfLink.find_by(id: @file_link2.id)
  end

  def test_destroy_folder_link
    assert @folder_link1.delete(commit: true), @folder_link1.errors.full_messages.to_sentence
    assert_nil DmsfLink.find_by(id: @folder_link1.id)
  end
end
