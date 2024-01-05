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

# WebDAV HEAD tests
class DmsfWebdavHeadTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_head_requires_authentication
    head "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
    check_headers_dont_exist
  end

  def test_head_responds_with_authentication
    head "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @admin
    assert_response :success
    check_headers_exist
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      head "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @admin
      assert_response :not_found
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      head "/dmsf/webdav/#{project1_uri}", params: nil, headers: @admin
      assert_response :success
    end
  end

  # NOTE: At present we use Rack to serve the file, this makes life easy however it removes the Etag
  #   header and invalidates the test - where as a folder listing will always not include a last-modified
  #   (but may include an etag, so there is an allowance for a 1 in 2 failure rate on (optionally) required
  #   headers)
  def test_head_responds_to_file
    head "/dmsf/webdav/#{@project1.identifier}/test.txt", params: nil, headers: @admin
    assert_response :success
    check_headers_exist
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      head "/dmsf/webdav/#{@project1.identifier}/test.txt", params: nil, headers: @admin
      assert_response :conflict
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      head "/dmsf/webdav/#{project1_uri}/test.txt", params: nil, headers: @admin
      assert_response :success
    end
  end

  def test_head_responds_to_file_anonymous_other_user_agent
    head "/dmsf/webdav/#{@project1.identifier}/test.txt", params: nil, headers: { HTTP_USER_AGENT: 'Other' }
    assert_response :unauthorized
    check_headers_dont_exist
  end

  def test_head_fails_when_file_not_found
    head "/dmsf/webdav/#{@project1.identifier}/not_here.txt", params: nil, headers: @admin
    assert_response :not_found
    check_headers_dont_exist
  end

  def test_head_fails_when_file_not_found_anonymous_other_user_agent
    head "/dmsf/webdav/#{@project1.identifier}/not_here.txt", params: nil, headers: { HTTP_USER_AGENT: 'Other' }
    assert_response :unauthorized
    check_headers_dont_exist
  end

  def test_head_fails_when_folder_not_found
    head '/dmsf/webdav/folder_not_here', params: nil, headers: @admin
    assert_response :not_found
    check_headers_dont_exist
  end

  def test_head_fails_when_folder_not_found_anonymous_other_user_agent
    head '/dmsf/webdav/folder_not_here', params: nil, headers: { HTTP_USER_AGENT: 'Other' }
    assert_response :unauthorized
    check_headers_dont_exist
  end

  def test_head_fails_when_project_is_not_enabled_for_dmsf
    head "/dmsf/webdav/#{@project2.identifier}/test.txt", params: nil, headers: @jsmith
    assert_response :not_found
    check_headers_dont_exist
  end

  def test_head_file_in_subproject
    head "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@file12.name}", params: nil, headers: @admin
    assert_response :success
  end

  def test_head_folder_in_subproject
    head "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@folder10.title}",
         params: nil,
         headers: @admin
    assert_response :success
  end
end
