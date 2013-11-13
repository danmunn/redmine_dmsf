# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, :dmsf_folders

  def setup
    @headers = credentials('admin')
    super
  end

  def teardown
    @headers = nil
  end

  test "OPTIONS requires no authentication for root level" do
    xml_http_request  :options, "dmsf/webdav"
    assert_response :success
  end

  test "OPTIONS returns expected Allow header" do
    xml_http_request  :options, "dmsf/webdav"
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert !response.headers["Allow"].nil? , "Allow header is empty or does not exist"
    assert response.headers["Allow"] == "OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK", "Allow header returns expected content"
  end

  test "OPTIONS returns expected Dav header" do
    xml_http_request  :options, "dmsf/webdav"
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert !response.headers["Dav"].nil? , "Dav header is empty or does not exist"
    assert response.headers["Dav"] == "1,2,3", "Dav header - expected: 1,2,3"
  end

  test "OPTIONS returns expected Ms-Auth-Via header" do
    xml_http_request  :options, "dmsf/webdav"
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert !response.headers["Ms-Author-Via"].nil? , "Ms-Author-Via header is empty or does not exist"
    assert response.headers["Ms-Author-Via"] == "DAV", "Ms-Author-Via header - expected: DAV"
  end

  test "OPTIONS requires authentication for non-root request" do
    xml_http_request :options, "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401 #Unauthorized
  end

  test "Un-authenticated OPTIONS returns expected Allow header" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert response.headers["Allow"].nil? , "Allow header should not exist"
    assert response.headers["Allow"] != "OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK", "Allow header returns expected"
  end

  test "Un-authenticated OPTIONS returns expected Dav header" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert response.headers["Dav"].nil? , "Dav header should not exist"
    assert response.headers["Dav"] != "1,2,3", "Dav header - expected: <None>"
  end

  test "Un-athenticated OPTIONS returns expected Ms-Auth-Via header" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert response.headers["Ms-Author-Via"].nil? , "Ms-Author-Via header should not exist"
    assert response.headers["Ms-Author-Via"] != "DAV", "Ms-Author-Via header - expected: <None>"
  end


  test "Authenticated OPTIONS returns expected Allow header" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(1).identifier}", nil, @headers
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert !response.headers["Allow"].nil? , "Allow header is empty or does not exist"
    assert response.headers["Allow"] == "OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK", "Allow header returns expected"
  end

  test "Authenticated OPTIONS returns expected Dav header" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(1).identifier}", nil, @headers
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert !response.headers["Dav"].nil? , "Dav header is empty or does not exist"
    assert response.headers["Dav"] == "1,2,3", "Dav header - expected: 1,2,3"
  end

  test "Authenticated OPTIONS returns expected Ms-Auth-Via header" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(1).identifier}", nil, @headers
    assert_response :success
    assert !(response.headers.nil? || response.headers.empty?), "Response headers are empty"
    assert !response.headers["Ms-Author-Via"].nil? , "Ms-Author-Via header is empty or does not exist"
    assert response.headers["Ms-Author-Via"] == "DAV", "Ms-Author-Via header - expected: DAV"
  end

  test "Authenticated OPTIONS returns 404 for not-found or non-dmsf-enabled items" do
    xml_http_request  :options, "dmsf/webdav/#{Project.find(2).identifier}", nil, @headers
    assert_response 404 #not found
    xml_http_request  :options, "dmsf/webdav/does-not-exist", nil, @headers
    assert_response 404 #not found
  end

  
end
