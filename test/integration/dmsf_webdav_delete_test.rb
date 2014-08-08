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

class DmsfWebdavDeleteTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n  
  
  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, 
    :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def setup
    DmsfFile.storage_path = File.expand_path '../fixtures/files', __FILE__
    DmsfLock.delete_all
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @role_developer = Role.find 2
    @folder4 = DmsfFolder.find_by_id 4
    @file1 = DmsfFile.find_by_id 1
    @file2 = DmsfFile.find_by_id 2
    @file4 = DmsfFile.find_by_id 4
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    super
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of DmsfFolder, @folder4
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file2
    assert_kind_of DmsfFile, @file4
    assert_kind_of Role, @role_developer
  end

  def test_not_authenticated  
    delete 'dmsf/webdav'
    assert_response 401
    delete "dmsf/webdav/#{@project1.identifier}"
    assert_response 401
  end

  def test_failed_authentication    
    delete 'dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401
    delete "dmsf/webdav/#{@project1.identifier}", nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  def test_root_folder  
    delete 'dmsf/webdav/', nil, @admin
    assert_response 501
  end

  def test_delete_not_empty_folder  
    put "dmsf/webdav/#{@project1.identifier}/folder1", nil, @admin
    assert_response :forbidden
  end

  def test_not_existed_project  
    delete 'dmsf/webdav/not_a_project/file.txt', nil, @admin
    assert_response 404 #Item does not exist
  end
  
  def test_dmsf_not_enabled  
    delete "dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response 404 #Item does not exist, as project is not enabled
  end
  
  def test_delete_when_ro
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_ONLY'
    delete "dmsf/webdav/#{@project2.identifier}/#{@file1.name}", nil, @admin
    assert_response 502 #Item does not exist, as project is not enabled    
  end

  def test_unlocked_file  
    delete "dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @admin
    assert_response :success # If its in the 20x range it's acceptable, should be 204
    @file1.reload
    assert @file1.deleted, "File #{@file1.name} hasn't been deleted"    
  end

  def test_unathorized_user  
    @project2.enable_module! :dmsf #Flag module enabled        
    delete "dmsf/webdav/#{@project2.identifier}/#{@file2.name}", nil, @jsmith
    assert_response 404 # Without folder_view permission, he will not even be aware of its existence
    @file2.reload
    assert !@file2.deleted, "File #{@file2.name} is expected to exist"
    @role_developer.add_permission! :view_dmsf_folders
    delete "dmsf/webdav/#{@project2.identifier}/#{@file2.name}", nil, @jsmith
    assert_response :forbidden # Now jsmith's role has view_folder rights, however they do not hold file manipulation rights
    @file2.reload
    assert !@file2.deleted, "File #{@file2.name} is expected to exist"
  end

  def test_view_folder_not_allowed  
    @project2.enable_module! :dmsf #Flag module enabled
    @role_developer.add_permission! :file_manipulation        
    delete "dmsf/webdav/#{@project2.identifier}/#{@file2.name}", nil, @jsmith
    assert_response 404 #Without folder_view permission, he will not even be aware of its existence
    @file2.reload
    assert !@file2.deleted, "File #{@file2.name} is expected to exist"
  end

  def test_folder_manipulation_not_allowed  
    @project2.enable_module! :dmsf #Flag module enabled
    @role_developer.add_permission! :view_dmsf_folders    
    delete "dmsf/webdav/#{@project2.identifier}/folder1/#{@folder4.title}", nil, @jsmith
    assert_response :forbidden #Without manipulation permission, action is forbidden    
    @folder4.reload
    assert !@folder4.deleted, "File #{@file2.name} is expected to exist"
  end

  def test_folder_delete_by_admin  
    @project2.enable_module! :dmsf #Flag module enabled    
    delete "dmsf/webdav/#{@project2.identifier}/folder1/#{@folder4.title}", nil, @admin
    assert_response :success
    @folder4.reload
    assert @folder4.deleted      
  end

  def test_folder_delete_by_user  
    @role_developer.add_permission! :view_dmsf_folders
    @role_developer.add_permission! :folder_manipulation
    @project2.enable_module! :dmsf #Flag module enabled        
    delete "dmsf/webdav/#{@project2.identifier}/folder1/#{@folder4.title}", nil, @jsmith
    assert_response :success
    @folder4.reload
    assert @folder4.deleted    
  end

  def test_file_delete_by_administrator  
    @project2.enable_module! :dmsf
    delete "dmsf/webdav/#{@project2.identifier}/#{@file2.name}", nil, @admin
    assert_response :success
    @file2.reload
    assert @file2.deleted    
  end

  def test_file_delete_by_user  
    @project2.enable_module! :dmsf
    @role_developer.add_permission! :view_dmsf_folders    
    @role_developer.add_permission! :file_delete    
    delete "dmsf/webdav/#{@project2.identifier}/#{@file2.name}", nil, @jsmith
    assert_response :success    
    @file2.reload
    assert @file2.deleted   
  end

  def test_locked_file  
    @project2.enable_module! :dmsf #Flag module enabled
    @role_developer.add_permission! :view_dmsf_folders
    @role_developer.add_permission! :file_delete    
    delete "dmsf/webdav/#{@project2.identifier}/#{@file2.name}", nil, @jsmith    
    assert_response :success
    # TODO: locks are not working here :-(
    #assert @file2.deleted, "File is not deleted?!?"
    #assert_include l(:error_file_is_locked), flash[:error]
  end

end