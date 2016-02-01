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

class DmsfWebdavDeleteTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n  
  
  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, 
    :dmsf_locks
   
  def setup
    DmsfFile.storage_path = File.expand_path '../../fixtures/files', __FILE__
    DmsfLock.delete_all
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @role = Role.find_by_id 1 # Manager
    @folder1 = DmsfFolder.find_by_id 1    
    @folder6 = DmsfFolder.find_by_id 6
    @file1 = DmsfFile.find_by_id 1    
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    DmsfFile.storage_path = File.expand_path '../../fixtures/files', __FILE__
    User.current = nil    
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder6
    assert_kind_of DmsfFile, @file1    
    assert_kind_of Role, @role
  end

  def test_not_authenticated
    delete '/dmsf/webdav'
    assert_response 401
  end
  
  def test_not_authenticated_project
    delete "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
  end

  def test_failed_authentication    
    delete '/dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401
  end
  
  def test_failed_authentication
    delete "/dmsf/webdav/#{@project1.identifier}", nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  def test_root_folder     
    delete '/dmsf/webdav', nil, @admin
    assert_response :error # 501
  end

  def test_delete_not_empty_folder  
    put "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", nil, @admin
    assert_response :forbidden
  end

  def test_not_existed_project  
    delete '/dmsf/webdav/not_a_project/file.txt', nil, @admin
    assert_response :missing # Item does not exist.
  end
  
  def test_dmsf_not_enabled  
    delete "/dmsf/webdav/#{@project1.identifier}/test.txt", nil, @jsmith
    assert_response :missing # Item does not exist, as project is not enabled.
  end
  
  def test_delete_when_ro
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_ONLY'
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @admin
    assert_response :error # 502 - Item does not exist, as project is not enabled.
  end

  def test_unlocked_file  
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @admin
    assert_response :success # If its in the 20x range it's acceptable, should be 204.
    @file1.reload
    assert @file1.deleted, "File #{@file1.name} hasn't been deleted"    
  end

  def test_unathorized_user  
    @project1.enable_module! :dmsf # Flag module enabled
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @jsmith
    assert_response :missing # Without folder_view permission, he will not even be aware of its existence.
    @file1.reload
    assert !@file1.deleted, "File #{@file1.name} is expected to exist"
  end
  
  def test_unathorized_user_forbidden
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @jsmith
    assert_response :forbidden # Now jsmith's role has view_folder rights, however they do not hold file manipulation rights.
    @file1.reload
    assert !@file1.deleted, "File #{@file1.name} is expected to exist"
  end

  def test_view_folder_not_allowed  
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :file_manipulation        
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", nil, @jsmith
    assert_response :missing # Without folder_view permission, he will not even be aware of its existence.
    @folder1.reload
    assert !@folder1.deleted, "Folder #{@folder1.title} is expected to exist"
  end

  def test_folder_manipulation_not_allowed  
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders    
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", nil, @jsmith
    assert_response :forbidden # Without manipulation permission, action is forbidden.
    @folder1.reload
    assert !@folder1.deleted, "Foler #{@folder1.title} is expected to exist"
  end

  def test_folder_delete_by_admin  
    @project1.enable_module! :dmsf # Flag module enabled    
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", nil, @admin
    assert_response :success
    @folder6.reload
    assert @folder6.deleted, "Folder #{@folder1.title} is not expected to exist"
  end

  def test_folder_delete_by_user  
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    @project1.enable_module! :dmsf # Flag module enabled        
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", nil, @jsmith
    assert_response :success
    @folder6.reload
    assert @folder6.deleted, "Folder #{@folder1.title} is not expected to exist"
  end

  def test_file_delete_by_administrator  
    @project1.enable_module! :dmsf
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @admin
    assert_response :success
    @file1.reload
    assert @file1.deleted, "File #{@file1.name} is not expected to exist"
  end

  def test_file_delete_by_user
    @project1.enable_module! :dmsf
    @role.add_permission! :view_dmsf_folders    
    @role.add_permission! :file_delete    
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @jsmith
    assert_response :success    
    @file1.reload
    assert @file1.deleted, "File #{@file1.name} is not expected to exist"
  end

  def test_locked_folder
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation    
    @folder6.lock!
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", nil, @jsmith
    assert_response 423 # Locked    
    @folder6.reload
    assert !@folder6.deleted, "Folder #{@folder6.title} is expected to exist"    
  end
  
  def test_locked_file
    @project1.enable_module! :dmsf
    @role.add_permission! :view_dmsf_folders    
    @role.add_permission! :file_delete    
    @file1.lock!
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil, @jsmith
    assert_response 423 # Locked        
    @file1.reload
    assert !@file1.deleted, "File #{@file1.name} is expected to exist"
  end

end