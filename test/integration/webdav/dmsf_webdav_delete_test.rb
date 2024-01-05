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

require File.expand_path('../../../test_helper', __FILE__)

# WebDAV delete test
class DmsfWebdavDeleteTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def test_not_authenticated
    delete '/dmsf/webdav'
    assert_response :unauthorized
  end

  def test_not_authenticated_project
    delete "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
  end

  def test_failed_authentication_global
    delete '/dmsf/webdav', params: nil, headers: credentials('admin', 'badpassword')
    assert_response :unauthorized
  end

  def test_failed_authentication
    delete "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: credentials('admin', 'badpassword')
    assert_response :unauthorized
  end

  def test_root_folder
    delete '/dmsf/webdav', params: nil, headers: @admin
    assert_response :not_implemented
  end

  def test_delete_not_empty_folder
    put "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", params: nil, headers: @admin
    assert_response :forbidden
  end

  def test_not_existed_project
    delete '/dmsf/webdav/not_a_project/file.txt', params: nil, headers: @admin
    assert_response :conflict
  end

  def test_dmsf_not_enabled
    @project1.disable_module! :dmsf
    delete "/dmsf/webdav/#{@project1.identifier}/test.txt", params: nil, headers: @jsmith
    assert_response :not_found # Item does not exist, as project is not enabled.
  end

  def test_delete_when_ro
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_strategy' => 'WEBDAV_READ_ONLY', 'dmsf_webdav' => '1' } do
      delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @admin
      assert_response :bad_gateway # WebDAV is read only
    end
  end

  def test_unlocked_file
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @admin
    assert_response :no_content
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} hasn't been deleted"
  end

  def test_unathorized_user
    @role.remove_permission! :view_dmsf_folders
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @jsmith
    assert_response :not_found # Without folder_view permission, he will not even be aware of its existence.
    @file1.reload
    assert_not @file1.deleted?, "File #{@file1.name} is expected to exist"
  end

  def test_unathorized_user_forbidden
    @role.remove_permission! :file_delete
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @jsmith
    assert_response :forbidden
    @file1.reload
    assert_not @file1.deleted?, "File #{@file1.name} is expected to exist"
  end

  def test_view_folder_not_allowed
    @role.remove_permission! :view_dmsf_folders
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", params: nil, headers: @jsmith
    assert_response :not_found # Without folder_view permission, he will not even be aware of its existence.
    @folder1.reload
    assert_not @folder1.deleted?, "Folder #{@folder1.title} is expected to exist"
  end

  def test_folder_manipulation_not_allowed
    @role.remove_permission! :folder_manipulation
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", params: nil, headers: @jsmith
    assert_response :forbidden # Without manipulation permission, action is forbidden.
    @folder1.reload
    assert_not @folder1.deleted?, "Foler #{@folder1.title} is expected to exist"
  end

  def test_folder_delete_by_admin
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", params: nil, headers: @admin
    assert_response :success
    @folder6.reload
    assert @folder6.deleted?, "Folder #{@folder6.title} is not expected to exist"
  end

  def test_folder_delete_by_user
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", params: nil, headers: @jsmith
    assert_response :success
    @folder6.reload
    assert @folder6.deleted?, "Folder #{@folder1.title} is not expected to exist"
  end

  def test_folder_delete_by_user_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", params: nil, headers: @jsmith
      assert_response :conflict
      p1name_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      delete "/dmsf/webdav/#{p1name_uri}/#{@folder6.title}", params: nil, headers: @jsmith
      assert_response :success
      @folder6.reload
      assert @folder6.deleted?, "Folder #{@folder6.title} is not expected to exist"
    end
  end

  def test_file_delete_by_administrator
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @admin
    assert_response :success
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} is not expected to exist"
  end

  def test_file_delete_by_user
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @jsmith
    assert_response :success
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} is not expected to exist"
  end

  def test_file_delete_by_user_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @jsmith
      assert_response :conflict
      p1name_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      delete "/dmsf/webdav/#{p1name_uri}/#{@file1.name}", params: nil, headers: @jsmith
      assert_response :success
      @file1.reload
      assert @file1.deleted?, "File #{@file1.name} is not expected to exist"
    end
  end

  def test_folder_delete_fragments
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/#frament=HTTP/1.1", params: nil, headers: @jsmith
    assert_response :bad_request
  end

  def test_locked_folder
    @folder6.lock!
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", params: nil, headers: @jsmith
    assert_response :locked
    @folder6.reload
    assert_not @folder6.deleted?, "Folder #{@folder6.title} is expected to exist"
  end

  def test_locked_file
    @file1.lock!
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @jsmith
    assert_response :locked
    @file1.reload
    assert_not @file1.deleted?, "File #{@file1.name} is expected to exist"
  end

  def test_non_versioned_file
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", params: nil, headers: @jsmith
    assert_response :success
    # The file should be destroyed
    assert_nil DmsfFile.visible.find_by(id: @file1.id)
  end

  def test_delete_file_in_subproject
    delete "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@file12.name}", params: nil, headers: @admin
    assert_response :success
  end

  def test_delete_folder_in_subproject
    delete "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@folder10.title}",
           params: nil,
           headers: @admin
    assert_response :success
  end

  def test_delete_folder_in_subproject_brackets
    project3_uri = Addressable::URI.encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project5))
    project1_uri = Addressable::URI.encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
    delete "/dmsf/webdav/#{project1_uri}/#{project3_uri}/#{@folder10.title}", params: nil, headers: @admin
    assert_response :success
  end

  def test_delete_subproject
    delete "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}", params: nil, headers: @admin
    assert_response :method_not_allowed
  end
end
