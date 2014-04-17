# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

class DmsfWebdavIntegrationTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, 
    :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @role_developer = Role.find 2    
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'    
    DmsfFile.storage_path = File.expand_path '../fixtures/files', __FILE__    
    super
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Role, @role_developer    
  end

  test 'should deny anonymous' do
    get 'dmsf/webdav'
    assert_response 401
  end

  test 'should deny failed authentication' do
    get 'dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  test 'should permit authenticated user' do
    get 'dmsf/webdav', nil, @admin
    assert_response :success
  end

  test 'should list DMSF enabled project' do
    get 'dmsf/webdav', nil, @admin
    assert_response :success

    assert !response.body.match(@project1.name).nil?, "Expected to find project #{@project1.name} in return data"
  end

  test 'should not list non-DMSF enabled project' do    
    get 'dmsf/webdav', nil, @jsmith
    assert_response :success    
    assert response.body.match(@project2.name).nil?, "Unexpected find of project #{@project2.name} in return data"
  end

  test 'should return status 404 when accessing non-existant or non dmsf-enabled project' do
    ## Test project resource object
    get 'dmsf/webdav/project_does_not_exist', nil, @jsmith 
    assert_response 404

    get "dmsf/webdav/#{@project2.identifier}", nil, @jsmith
    assert_response 404

    ## Test dmsf resource object
    get 'dmsf/webdav/project_does_not_exist/test1', nil, @jsmith
    assert_response 404

    get "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 404
  end

  test 'download file from DMSF enabled project' do    
    # TODO: the storage path is not set as expected => reset
    DmsfFile.storage_path = File.expand_path('../../fixtures/files', __FILE__)    
    get "dmsf/webdav/#{@project1.identifier}/test.txt", nil, @admin    
    assert_response :success
    assert_equal response.body, '1234', "File downloaded with unexpected contents: '#{response.body}'"
  end

  test 'should list dmsf contents within project' do
    get "dmsf/webdav/#{@project1.identifier}", nil, @admin
    assert_response :success
    folder = DmsfFolder.find_by_id 1
    assert folder
    assert response.body.match(folder.title), "Expected to find #{folder.title} in return data"
    file = DmsfFile.find_by_id 1
    assert file
    assert response.body.match(file.name), "Expected to find #{file.name} in return data"
  end

  test 'user assigned to project' do
    # We'll be using project 2 and user jsmith for this test (Manager)       
    get "dmsf/webdav/#{@project2.identifier}", nil, @jsmith
    assert_response 404

    @project2.enable_module! :dmsf #Flag module enabled

    get "dmsf/webdav/#{@project2.identifier}", nil, @jsmith
    assert_response 404

    @role_developer.add_permission! :view_dmsf_folders #assign rights

    get "dmsf/webdav/#{@project2.identifier}", nil, @jsmith
    assert_response :success

    get "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 403 #Access is not granted as does not hold view_dmsf_files role (yet)

    @role_developer.add_permission! :view_dmsf_files #assign rights
    # TODO: the storage path is not set as expected => reset
    DmsfFile.storage_path = File.expand_path('../../fixtures/files', __FILE__)    
    get "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response :success
    assert_equal response.body, '1234', "File downloaded with unexpected contents: '#{response.body}'"
  end

end