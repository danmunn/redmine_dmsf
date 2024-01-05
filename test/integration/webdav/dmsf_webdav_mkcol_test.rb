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

# WebDAV MKCOL tests
class DmsfWebdavMkcolTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders

  def test_mkcol_requires_authentication
    process :mkcol, '/dmsf/webdav/test1'
    assert_response :unauthorized
  end

  def test_mkcol_fails_to_create_folder_at_root_level
    process :mkcol, '/dmsf/webdav/test1', params: nil, headers: @admin
    assert_response :method_not_allowed
  end

  def test_should_not_succeed_on_a_non_existant_project
    process :mkcol, '/dmsf/webdav/project_doesnt_exist/test1', params: nil, headers: @admin
    assert_response :conflict
  end

  def test_should_not_succed_on_a_non_dmsf_enabled_project
    @project1.disable_module! :dmsf
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/folder", params: nil, headers: @jsmith
    assert_response :not_found
  end

  def test_should_not_create_folder_without_permissions
    @role.remove_permission! :folder_manipulation
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/folder", params: nil, headers: @jsmith
    assert_response :forbidden
  end

  def test_should_fail_to_create_folder_that_already_exists
    process :mkcol,
            "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}",
            params: nil,
            headers: @jsmith
    assert_response :method_not_allowed
  end

  def test_should_create_folder_for_non_admin_user_with_rights
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test1", params: nil, headers: @jsmith
    assert_response :success
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      project1_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test2", params: nil, headers: @jsmith
      assert_response :conflict
      process :mkcol, "/dmsf/webdav/#{project1_uri}/test3", params: nil, headers: @jsmith
      assert_response :success # Created
    end
  end

  def test_create_folder_in_subproject
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/test1",
            params: nil,
            headers: @admin
    assert_response :success
  end

  def test_create_folder_with_square_brackets_of_the_same_name_as_a_sub_project
    project3_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project5))
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/#{project3_uri}",
            params: nil,
            headers: @admin
    assert_response :method_not_allowed
  end

  def test_create_folder_of_the_same_name_as_a_sub_project
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}",
            params: nil,
            headers: @admin
    assert_response :method_not_allowed
  end

  def test_create_folder_with_square_brackets
    folder_name = ERB::Util.url_encode('[new folder]')
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/#{folder_name}",
            params: nil,
            headers: @admin
    assert_response :conflict # Square brackets are not allowed in project names
  end
end
