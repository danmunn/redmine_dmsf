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

class DmsfWebdavMkcolTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, :dmsf_folders

  def setup
    @headers = credentials('admin')
    super
  end

  def teardown
    @headers = nil
  end

  test "MKCOL requires authentication" do
    xml_http_request  :mkcol, "dmsf/webdav/test1"
    assert_response 401
  end

  test "MKCOL fails to create folder at root level" do
    xml_http_request  :mkcol, "dmsf/webdav/test1", nil, @headers
    assert_response 501 #Not Implemented at this level
  end

  test "should not succeed on a non-existant project" do
    xml_http_request  :mkcol, "dmsf/webdav/project_doesnt_exist/test1", nil, @headers
    assert_response 404 #Not found
  end

  test "should not succed on a non-dmsf enabled project" do
    xml_http_request :mkcol, "dmsf/webdav/#{Project.find(2).identifier}/test1", nil, @headers
    assert_response 404
  end

  test "should create folder on dmsf enabled project" do
    xml_http_request :mkcol, "dmsf/webdav/#{Project.find(1).identifier}/test1", nil, @headers
    assert_response :success
  end

  test "should fail to create folder that already exists" do
    xml_http_request :mkcol, "dmsf/webdav/#{Project.find(1).identifier}/test1", nil, @headers
    assert_response :success
    xml_http_request :mkcol, "dmsf/webdav/#{Project.find(1).identifier}/test1", nil, @headers
    assert_response 405 #Method not Allowed
  end

  test "should fail to create folder for user without rights" do
    xml_http_request :mkcol, "dmsf/webdav/#{Project.find(1).identifier}/test1", nil, credentials('jsmith')
    assert_response 403 #Forbidden
  end

  test "should create folder for non-admin user with rights" do

    role = Role.find(2) #Developer role
    jsmith = credentials('jsmith')
    user = User.find(2)
    project = Project.find(2)

    role.add_permission! :folder_manipulation
    project.enable_module! :dmsf

    xml_http_request :mkcol, "dmsf/webdav/#{project.identifier}/test1", nil, credentials('jsmith')
    assert_response :success

    role.remove_permission! :folder_manipulation
    project.disable_module! :dmsf

  end

  
end
