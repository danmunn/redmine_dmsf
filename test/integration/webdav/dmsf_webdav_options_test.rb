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

# WebDAV OPTIONS tests
class DmsfWebdavOptionsTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders

  def test_options_requires_no_authentication_for_root_level
    process :options, '/dmsf/webdav'
    assert_response :success
  end

  def test_options_returns_expected_allow_header_for_ro
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_strategy' => 'WEBDAV_READ_ONLY', 'dmsf_webdav' => '1' } do
      process :options, '/dmsf/webdav'
      assert_response :success
      assert_not response.headers.blank?, 'Response headers are empty'
      assert response.headers['Allow'], 'Allow header is empty or does not exist'
      assert_equal response.headers['Allow'], 'OPTIONS,HEAD,GET,PROPFIND'
    end
  end

  def test_options_returns_expected_allow_header_for_rw
    process :options, '/dmsf/webdav'
    assert_response :success
    assert_not response.headers.blank?, 'Response headers are empty'
    assert response.headers['Allow'], 'Allow header is empty or does not exist'
    assert_equal response.headers['Allow'],
                 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
  end

  def test_options_returns_expected_dav_header
    process :options, '/dmsf/webdav'
    assert_response :success
    assert_not response.headers.blank?, 'Response headers are empty'
    assert response.headers['Dav'], 'Dav header is empty or does not exist'
  end

  def test_options_returns_expected_ms_auth_via_header
    process :options, '/dmsf/webdav'
    assert_response :success
    assert_not response.headers.blank?, 'Response headers are empty'
    assert response.headers['Ms-Author-Via'], 'Ms-Author-Via header is empty or does not exist'
    assert response.headers['Ms-Author-Via'] == 'DAV', 'Ms-Author-Via header - expected: DAV'
  end

  def test_options_requires_authentication_for_non_root_request
    process :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
  end

  def test_un_authenticated_options_returns_expected_allow_header
    process :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
    assert_not response.headers.blank?, 'Response headers are empty'
    assert_nil response.headers['Allow'], 'Allow header should not exist'
  end

  def test_un_authenticated_options_returns_expected_dav_header
    process :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
    assert_not response.headers.blank?, 'Response headers are empty'
    assert_nil response.headers['Dav'], 'Dav header should not exist'
  end

  def test_un_authenticated_options_returns_expected_ms_auth_via_header
    process :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
    assert_not response.headers.blank?, 'Response headers are empty'
    assert_nil response.headers['Ms-Author-Via'], 'Ms-Author-Via header should not exist'
  end

  def test_authenticated_options_returns_expected_allow_header
    process :options, "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @jsmith
    assert_response :success
    assert_not response.headers.blank?, 'Response headers are empty'
    assert response.headers['Allow'], 'Allow header is empty or does not exist'
    assert_equal response.headers['Allow'],
                 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
  end

  def test_authenticated_options_returns_expected_dav_header
    process :options, "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @jsmith
    assert_response :success
    assert_not response.headers.blank?, 'Response headers are empty'
    assert response.headers['Dav'], 'Dav header is empty or does not exist'
  end

  def test_authenticated_options_returns_expected_ms_auth_via_header
    process :options, "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @jsmith
    assert_response :success
    assert_not response.headers.blank?, 'Response headers are empty'
    assert response.headers['Ms-Author-Via'], 'Ms-Author-Via header is empty or does not exist'
    assert response.headers['Ms-Author-Via'] == 'DAV', 'Ms-Author-Via header - expected: DAV'
  end

  def test_un_authenticated_options_for_msoffice_user_agent
    process :options,
            "/dmsf/webdav/#{@project1.identifier}",
            params: nil,
            headers: { HTTP_USER_AGENT: 'Microsoft Office Word 2014' }
    assert_response :unauthorized
  end

  def test_authenticated_options_for_msoffice_user_agent
    process :options, "/dmsf/webdav/#{@project1.identifier}",
            params: nil,
            headers: @admin.merge!({ HTTP_USER_AGENT: 'Microsoft Office Word 2014' })
    assert_response :success
  end

  def test_un_authenticated_options_for_other_user_agent
    process :options, "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: { HTTP_USER_AGENT: 'Other' }
    assert_response :unauthorized
  end

  def test_authenticated_options_for_other_user_agent
    process :options,
            "/dmsf/webdav/#{@project1.identifier}",
            params: nil,
            headers: @admin.merge!({ HTTP_USER_AGENT: 'Other' })
    assert_response :success

    project1_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
    process :options, "/dmsf/webdav/#{project1_uri}", params: nil, headers: @admin.merge!({ HTTP_USER_AGENT: 'Other' })
    assert_response :success
  end

  def test_options_for_subproject
    process :options, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}", params: nil, headers: @admin
    assert_response :success
  end
end
