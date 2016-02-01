# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

class DmsfWebdavGetTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @role = Role.find_by_id 1 # Manager
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'    
    DmsfFile.storage_path = File.expand_path '../../fixtures/files', __FILE__
    User.current = nil
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Role, @role
  end

  def test_should_deny_anonymous
    get '/dmsf/webdav'
    assert_response 401
  end

  def test_should_deny_failed_authentication
    get '/dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  def test_should_permit_authenticated_user
    get '/dmsf/webdav', nil, @admin
    assert_response :success
  end

  def test_should_list_dmsf_enabled_project
    get '/dmsf/webdav', nil, @admin
    assert_response :success
    assert !response.body.match(@project1.name).nil?, "Expected to find project #{@project1.name} in return data"
  end

  def test_should_not_list_non_dmsf_enabled_project
    get '/dmsf/webdav', nil, @jsmith
    assert_response :success    
    assert response.body.match(@project2.name).nil?, "Unexpected find of project #{@project2.name} in return data"
  end

  def test_should_return_status_404_when_project_does_not_exist
    @project1.enable_module! :dmsf # Flag module enabled
    get '/dmsf/webdav/project_does_not_exist', nil, @jsmith 
    assert_response :missing
  end

  def test_should_return_status_404_when_dmsf_not_enabled
    get "/dmsf/webdav/#{@project2.identifier}", nil, @jsmith
    assert_response :missing
  end   

  def test_download_file_from_dmsf_enabled_project
    #@project1.enable_module! :dmsf # Flag module enabled    
    get "/dmsf/webdav/#{@project1.identifier}/test.txt", nil, @admin        
    assert_response :success
    assert_equal response.body, '1234', 
      "File downloaded with unexpected contents: '#{response.body}'"
  end

  def test_should_list_dmsf_contents_within_project
    get "/dmsf/webdav/#{@project1.identifier}", nil, @admin
    assert_response :success
    folder = DmsfFolder.find_by_id 1
    assert folder
    assert response.body.match(folder.title), 
      "Expected to find #{folder.title} in return data"
    file = DmsfFile.find_by_id 1
    assert file
    assert response.body.match(file.name), 
      "Expected to find #{file.name} in return data"
  end

  def test_user_assigned_to_project_dmsf_module_not_enabled    
    get "/dmsf/webdav/#{@project1.identifier}", nil, @jsmith
    assert_response :missing
  end
  
  def test_user_assigned_to_project_folder_forbidden
    @project2.enable_module! :dmsf # Flag module enabled
    get "/dmsf/webdav/#{@project1.identifier}", nil, @jsmith
    assert_response :missing
  end

  def test_user_assigned_to_project_folder_ok
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :view_dmsf_files
    get "/dmsf/webdav/#{@project1.identifier}", nil, @jsmith
    assert_response :success
  end
  
  def test_user_assigned_to_project_file_forbidden
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders    
    get "/dmsf/webdav/#{@project1.identifier}/test.txt", nil, @jsmith
    assert_response :forbidden
  end
  
  def test_user_assigned_to_project_file_ok
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :view_dmsf_files  
    get "/dmsf/webdav/#{@project1.identifier}/test.txt", nil, @jsmith
    assert_response :success
    assert_equal response.body, '1234', 
      "File downloaded with unexpected contents: '#{response.body}'"
  end

end