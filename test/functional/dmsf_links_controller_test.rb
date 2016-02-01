# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-16 Karel Pičman <karel.picman@lbcfree.net>
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

class DmsfLinksControllerTest < RedmineDmsf::Test::TestCase

  fixtures :users, :email_addresses, :projects, :members, :dmsf_files, 
    :dmsf_file_revisions, :dmsf_folders, :dmsf_links, :roles, :member_roles
  
  def setup
    @user_admin = User.find_by_id 1
    assert_not_nil @user_admin
    @user_member = User.find_by_id 2
    assert_not_nil @user_member
    @user_non_member = User.find_by_id 3
    assert_not_nil @user_non_member
    @role_manager = Role.where(:name => 'Manager').first
    assert_not_nil @role_manager
    @role_manager.add_permission! :file_manipulation
    @role_developer = Role.where(:name => 'Developer').first
    assert_not_nil @role_developer
    @role_developer.add_permission! :file_manipulation
    @project1 = Project.find_by_id 1
    assert_not_nil @project1
    @project1.enable_module! :dmsf
    @project2 = Project.find_by_id 2
    assert_not_nil @project2
    @project2.enable_module! :dmsf    
    @folder1 = DmsfFolder.find_by_id 1 # project1/folder1
    @folder2 = DmsfFolder.find_by_id 2 # project1/folder1/folder2
    @folder3 = DmsfFolder.find_by_id 3 # project2/folder3
    @file1 = DmsfFile.find_by_id 1 # project1/file1
    @file2 = DmsfFile.find_by_id 2 # project2/file2
    @file4 = DmsfFile.find_by_id 4 # project1/folder2/file4
    @file6 = DmsfFile.find_by_id 6 # project2/folder3/file6    
    @file_link = DmsfLink.find_by_id 1
    @request.env['HTTP_REFERER'] = dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
    @request.session[:user_id] = @user_member.id
    User.current = nil
  end
  
  def test_truth
    assert_kind_of User, @user_admin
    assert_kind_of User, @user_member
    assert_kind_of User, @user_non_member
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Role, @role_manager
    assert_kind_of Role, @role_developer
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder2
    assert_kind_of DmsfFolder, @folder3
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file2
    assert_kind_of DmsfFile, @file4
    assert_kind_of DmsfFile, @file6
    assert_kind_of DmsfLink, @file_link
  end
  
  def test_authorize_admin    
    @request.session[:user_id] = @user_admin.id
    get :new, :project_id => @project1.id
    assert_response :success
    assert_template 'new'   
  end

  def test_authorize_non_member
    @request.session[:user_id] = @user_non_member.id
    get :new, :project_id => @project2.id    
    assert_response :forbidden
  end
    
  def test_authorize_member_ok
    @request.session[:user_id] = @user_member.id
    get :new, :project_id => @project1.id
    assert_response :success
  end
  
  def test_authorize_member_no_module
    # Without the module
    @project1.disable_module!(:dmsf)    
    get :new, :project_id => @project1.id
    assert_response :forbidden    
  end
  
  def test_authorize_forbidden
    # Without permissions
    @project1.enable_module!(:dmsf)
    @role_manager.remove_permission! :file_manipulation
    get :new, :project_id => @project1.id
    assert_response :forbidden    
  end
  
  def test_new    
    get :new, :project_id => @project1.id
    assert_response :success
  end
  
  def test_create_file_link_from_f1
    # 1. File link in a folder from another folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :target_project_id => @project2.id,
        :dmsf_folder_id => @folder1.id,
        :target_file_id => @file6.id,
        :target_folder_id => @folder3.id,
        :name => 'file_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
  
  def test_create_file_link_from_f2
    # 2. File link in a folder from another root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :dmsf_folder_id => @folder1.id,
        :target_project_id => @project2.id,        
        :target_file_id => @file2.id,
        :target_folder_id => 'Documents',
        :name => 'file_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
  
  def test_create_file_link_from_f3
    # 3. File link in a root folder from another folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :target_project_id => @project2.id,        
        :target_file_id => @file6.id,
        :target_folder_id => @folder3.id,
        :name => 'file_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
  end
  
  def test_create_file_link_from_f4
    # 4. File link in a root folder from another root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :target_project_id => @project2.id,        
        :target_file_id => @file2.id,        
        :name => 'file_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
  end

  def test_create_folder_link_from_d1
    # 1. Folder link in a folder from another folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :dmsf_folder_id => @folder1.id,
        :target_project_id => @project2.id,        
        :target_folder_id => @folder3.id,
        :name => 'folder_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
    
  def test_create_folder_link_from_d2
    # 2. Folder link in a folder from another root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :dmsf_folder_id => @folder1.id,
        :target_project_id => @project2.id,        
        :name => 'folder_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
    
  def test_create_folder_link_from_d3
    # 3. Folder link in a root folder from another folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id,         
        :target_project_id => @project2.id,                
        :target_folder_id => @folder3.id,
        :name => 'folder_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
  end
    
  def test_create_folder_link_from_d4
    # 4. Folder link in a root folder from another root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :target_project_id => @project2.id,                
        :name => 'folder_link',
        :type => 'link_from'
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
  end
  
  def test_create_file_link_to_f1
    # 1. File link to a root folder from another folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id,
        :dmsf_file_id => @file1.id,
        :target_project_id => @project2.id,
        :target_folder_id => @folder3.id,        
        :name => 'file_link',
        :type => 'link_to'
      }
    end    
    assert_redirected_to dmsf_file_path(@file1)        
  end
    
  def test_create_file_link_to_f2
    # 2. File link to a folder from another folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project2.id,         
        :dmsf_folder_id => @folder3.id,
        :target_project_id => @project1.id,
        :target_folder_id => @folder1.id,
        :dmsf_file_id => @file6.id,
        :name => 'file_link',
        :type => 'link_to'
      }
    end    
    assert_redirected_to dmsf_file_path(@file6)
  end
    
  def test_create_file_link_to_f3
    # 3. File link to a root folder from another root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project2.id,                 
        :target_project_id => @project1.id,        
        :dmsf_file_id => @file6.id,
        :name => 'file_link',
        :type => 'link_to'
      }
    end    
    assert_redirected_to dmsf_file_path(@file6)
  end
    
  def test_create_file_link_to_f4
    # 4. File link to a folder from another root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project2.id,         
        :dmsf_folder_id => @folder3.id,
        :target_project_id => @project1.id,        
        :dmsf_file_id => @file6.id,
        :name => 'file_link',
        :type => 'link_to'
      }
    end    
    assert_redirected_to dmsf_file_path(@file6)
  end
  
  def test_create_external_link_from
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id,        
        :target_project_id => @project1.id,        
        :name => 'file_link',
        :external_link => 'true',
        :type => 'link_from'        
      }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id)
  end
  
  def test_create_folder_link_to_f1
    # 1. Folder link to a root folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id,         
        :dmsf_folder_id => @folder1.id,
        :target_project_id => @project2.id,        
        :name => 'folder_link',
        :type => 'link_to'
      }
    end    
    assert_redirected_to edit_dmsf_path(:id => @project1.id, :folder_id => @folder1.id)
  end
  
  def test_create_folder_link_to_f2
    # 2. Folder link to a folder
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id,         
        :dmsf_folder_id => @folder1.id,
        :target_project_id => @project2.id,
        :target_folder_id => @folder3.id,        
        :name => 'folder_link',
        :type => 'link_to'
      }
    end    
    assert_redirected_to edit_dmsf_path(:id => @project1.id, :folder_id => @folder1.id)               
  end
  
  def test_destroy          
    assert_difference 'DmsfLink.visible.count', -1 do
      delete :destroy, :project_id => @project1.id, :id => @file_link.id
    end
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
  
  def test_restore_forbidden
    # Missing permissions
    @request.env['HTTP_REFERER'] = trash_dmsf_path(:id => @project1.id)        
    @role_manager.remove_permission! :file_manipulation
    get :restore, :project_id => @project1.id, :id => @file_link.id
    assert_response :forbidden
  end
    
  def test_restore_ok
    # Permissions OK
    @request.env['HTTP_REFERER'] = trash_dmsf_path(:id => @project1.id)        
    @role_manager.add_permission! :file_manipulation
    get :restore, :project_id => @project1.id, :id => @file_link.id
    assert_response :redirect
  end

end