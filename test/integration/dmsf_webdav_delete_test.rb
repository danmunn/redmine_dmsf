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
    DmsfFile.storage_path = File.expand_path '../fixtures/files', __FILE__
    DmsfLock.delete_all
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

  test 'DELETE denied unless authenticated' do
    delete 'dmsf/webdav'
    assert_response 401

    delete "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401
  end

  test 'DELETE denied with failed authentication' do
    delete 'dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401

    delete "dmsf/webdav/#{@project1.identifier}", nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  test 'DELETE denied on project folder do' do
    delete 'dmsf/webdav/', nil, @admin
    assert_response 501
  end

  test 'DELETE denied on folder with children' do
    put "dmsf/webdav/#{@project1.identifier}/folder1", nil, @admin
    assert_response 403 #forbidden
  end

  test 'DELETE failed on non-existant project' do
    delete 'dmsf/webdav/not_a_project/file.txt', nil, @admin
    assert_response 404 #Item does not exist
  end
  
  test 'DELETE failed on a non-dmsf-enabled project' do
    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 404 #Item does not exist, as project is not enabled
  end

  test 'DELETE failed when the strategy is read only' do
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_ONLY'
    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @admin
    assert_response 502 #Item does not exist, as project is not enabled    
  end

  test 'DELETE succeeds on unlocked file' do    
    file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
    assert !file.nil?, 'File test.txt is expected to exist'

    assert_difference('@project1.dmsf_files.visible.count', -1) do
      delete "dmsf/webdav/#{@project1.identifier}/test.txt", nil, @admin
      assert_response :success #If its in the 20x range it's acceptable, should be 204
    end

    file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
    assert file.nil?, 'File test.txt is expected to not exist'
  end

  test 'DELETE denied on existing file by unauthorised user' do        
    @project2.enable_module! :dmsf #Flag module enabled

    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 404 #Without folder_view permission, he will not even be aware of its existence

    @role_developer.add_permission! :view_dmsf_folders

    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 403 #Now jsmith's role has view_folder rights, however they do not hold file manipulation rights

    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert file, 'File test.txt is expected to exist'
  end

  test 'DELETE fails when file_manipulation is granted but view_dmsf_folders is not' do    
    @project2.enable_module! :dmsf #Flag module enabled
    @role_developer.add_permission! :file_manipulation

    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 404 #Without folder_view permission, he will not even be aware of its existence

    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert file, 'File test.txt is expected to exist'
  end

  test 'DELETE fails on folder without folder_manipulation permission' do    
    folder = DmsfFolder.find 3 #project 2/folder1

    @project2.enable_module! :dmsf #Flag module enabled
    @role_developer.add_permission! :view_dmsf_folders

    assert_no_difference('folder.subfolders.length') do
      delete "dmsf/webdav/#{@project2.identifier}/folder1/folder2", nil, @jsmith
      assert_response 403 #Without manipulation permission, action is forbidden
    end
  end

  test 'DELETE folder is successful by administrator' do    
    folder = DmsfFolder.find 3 #project 2/folder1

    @project2.enable_module! :dmsf #Flag module enabled

    assert_difference('folder.subfolders.length', -1) do
      delete "dmsf/webdav/#{@project2.identifier}/folder1/folder2", nil, @admin
      assert_response :success
      folder.reload #We know there is a change, but does the object?
    end
  end

  test 'DELETE folder is successful by user with roles' do    
    folder = DmsfFolder.find 3 #project 2/folder1    

    @role_developer.add_permission! :view_dmsf_folders
    @role_developer.add_permission! :folder_manipulation

    @project2.enable_module! :dmsf #Flag module enabled

    assert_difference('folder.subfolders.length', -1) do
      delete "dmsf/webdav/#{@project2.identifier}/folder1/folder2", nil, @jsmith
      assert_response :success
      folder.reload #We know there is a change, but does the object?
    end
  end

  test 'DELETE file is successful by administrator' do    
    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert file, 'File test.txt is expected to exist'

    @project2.enable_module! :dmsf

    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @admin
    assert_response :success

    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert_nil file, 'File test.txt is expected to not exist'
  end

  test 'DELETE file is successful by user with correct permissions' do    
    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'

    @project2.enable_module! :dmsf

    @role_developer.add_permission! :view_dmsf_folders
    @role_developer.add_permission! :file_manipulation

    assert file, 'File test.txt is expected to exist'

    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response :success

    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert_nil file, 'File test.txt is expected to not exist'
  end

  test 'DELETE fails when file is locked' do    
    @project2.enable_module! :dmsf #Flag module enabled

    @role_developer.add_permission! :view_dmsf_folders
    @role_developer.add_permission! :file_manipulation

    log_user 'admin', 'admin' #login as admin

    assert !User.current.anonymous?, 'Current user is not anonymous'

    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert file.lock!, "File failed to be locked by #{User.current.name}"

    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 423 #Locked

    file = DmsfFile.find_file_by_name @project2, nil, 'test.txt'
    assert file, 'File test.txt is expected to exist'

    User.current = User.find 1 #For some reason the above delete request changes User.current

    file.unlock!
    assert !file.locked?, "File failed to unlock by #{User.current.name}"
  end

end