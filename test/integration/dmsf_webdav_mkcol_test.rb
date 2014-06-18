# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, 
    :dmsf_folders

  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @role_developer = Role.find 2
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    super
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Role, @role_developer    
  end
  
  def test_mkcol_requires_authentication
    xml_http_request  :mkcol, 'dmsf/webdav/test1'
    assert_response 401
  end

  def test_mkcol_fails_to_create_folder_at_root_level
    xml_http_request  :mkcol, 'dmsf/webdav/test1', nil, @admin
    assert_response 501 #Not Implemented at this level
  end

  def test_should_not_succeed_on_a_non_existant_project
    xml_http_request  :mkcol, 'dmsf/webdav/project_doesnt_exist/test1', nil, @admin
    assert_response 404 #Not found
  end

  def test_should_not_succed_on_a_non_dmsf_enabled_project
    xml_http_request :mkcol, "dmsf/webdav/#{@project2.identifier}/test1", nil, @jsmith
    assert_response :forbidden
  end

  def test_should_create_folder_on_dmsf_enabled_project
    xml_http_request :mkcol, "dmsf/webdav/#{@project1.identifier}/test1", nil, @admin
    assert_response :success
  end

  def test_should_fail_to_create_folder_that_already_exists
    xml_http_request :mkcol, "dmsf/webdav/#{@project1.identifier}/test1", nil, @admin
    assert_response :success
    xml_http_request :mkcol, "dmsf/webdav/#{@project1.identifier}/test1", nil, @admin
    assert_response 405 #Method not Allowed
  end

  def test_should_fail_to_create_folder_for_user_without_rights
    xml_http_request :mkcol, "dmsf/webdav/#{@project1.identifier}/test1", nil, @jsmith
    assert_response 403 #Forbidden
  end

  def test_should_create_folder_for_non_admin_user_with_rights
    @role_developer.add_permission! :folder_manipulation
    @project2.enable_module! :dmsf
    xml_http_request :mkcol, "dmsf/webdav/#{@project2.identifier}/test1", nil, @jsmith
    assert_response :success    
  end
  
end