# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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

class DmsfWebdavOptionsTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders

  def setup
    @admin = credentials 'admin'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end
  
  def test_options_requires_no_authentication_for_root_level
    xml_http_request  :options, '/dmsf/webdav'
    assert_response :success
  end

  def test_options_returns_expected_allow_header
    xml_http_request  :options, '/dmsf/webdav'
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert response.headers['Allow'] , 'Allow header is empty or does not exist'
    assert response.headers['Allow'] == 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK', 'Allow header returns expected content'
  end

  def test_options_returns_expected_dav_header
    xml_http_request  :options, '/dmsf/webdav'
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert response.headers['Dav'] , 'Dav header is empty or does not exist'    
  end

  def test_options_returns_expected_ms_auth_via_header
    xml_http_request  :options, '/dmsf/webdav'
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert response.headers['Ms-Author-Via'] , 'Ms-Author-Via header is empty or does not exist'
    assert response.headers['Ms-Author-Via'] == 'DAV', 'Ms-Author-Via header - expected: DAV'
  end

  def test_options_requires_authentication_for_non_root_request
    xml_http_request :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401 # Unauthorized
  end

  def test_un_authenticated_options_returns_expected_allow_header
    xml_http_request  :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert_nil response.headers['Allow'] , 'Allow header should not exist'    
  end

  def test_un_authenticated_options_returns_expected_dav_header
    xml_http_request  :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert_nil response.headers['Dav'] , 'Dav header should not exist'    
  end

  def test_un_authenticated_options_returns_expected_ms_auth_via_header
    xml_http_request  :options, "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert_nil response.headers['Ms-Author-Via'] , 'Ms-Author-Via header should not exist'    
  end

  def test_authenticated_options_returns_expected_allow_header
    xml_http_request  :options, "/dmsf/webdav/#{@project1.identifier}", nil, @admin
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert response.headers['Allow'], 'Allow header is empty or does not exist'
    assert response.headers['Allow'] == 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK', 'Allow header returns expected'
  end

  def test_authenticated_options_returns_expected_dav_header
    xml_http_request  :options, "/dmsf/webdav/#{@project1.identifier}", nil, @admin
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert response.headers['Dav'], 'Dav header is empty or does not exist'    
  end

  def test_authenticated_options_returns_expected_ms_auth_via_header
    xml_http_request  :options, "/dmsf/webdav/#{@project1.identifier}", nil, @admin
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), 'Response headers are empty'
    assert response.headers['Ms-Author-Via'], 'Ms-Author-Via header is empty or does not exist'
    assert response.headers['Ms-Author-Via'] == 'DAV', 'Ms-Author-Via header - expected: DAV'
  end

  def test_authenticated_options_returns_401_for_non_dmsf_enabled_items
    xml_http_request  :options, "/dmsf/webdav/#{@project2.identifier}", nil, @jsmith
    assert_response 401 # refused
  end
  
  def test_authenticated_options_returns_401_for_not_found
    xml_http_request  :options, '/dmsf/webdav/does-not-exist', nil, @jsmith
    assert_response 401 # refused
  end

end