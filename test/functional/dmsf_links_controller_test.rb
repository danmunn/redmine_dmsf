# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2014 Karel Pičman <karel.picman@lbcfree.net>
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

  fixtures :projects, :members, :dmsf_files, :dmsf_file_revisions, 
    :dmsf_folders, :dmsf_links, :roles, :member_roles
  
  def setup
    @user_admin = User.find_by_id 1    
    @user_member = User.find_by_id 2    
    @user_non_member = User.find_by_id 3    
    @project1 = Project.find_by_id 1
    assert_not_nil @project1
    @project1.enable_module! :dmsf
    @role_manager = Role.where(:name => 'Manager').first
    assert_not_nil @role_manager
    @role_manager.add_permission! :file_manipulation
    @folder1 = DmsfFolder.find_by_id 1
    @file1 = DmsfFile.find_by_id 1
    @request.session[:user_id] = @user_member.id
    @file_link = DmsfLink.find_by_id 1
    @request.env['HTTP_REFERER'] = dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
  
    def test_truth
    assert_kind_of User, @user_admin
    assert_kind_of User, @user_member
    assert_kind_of User, @user_non_member
    assert_kind_of Project, @project1
    assert_kind_of Role, @role_manager
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfLink, @file_link
  end
  
  def test_authorize
    # Admin
    @request.session[:user_id] = @user_admin.id
    get :new, :project_id => @project1.id
    assert_response :success
    assert_template 'new'        

    # Non member
    @request.session[:user_id] = @user_non_member.id    
    get :new, :project_id => @project1.id
    assert_response :forbidden
    
    # Member    
    @request.session[:user_id] = @user_member.id
    get :new, :project_id => @project1.id
    assert_response :success
            
    # Without the module
    @project1.disable_module!(:dmsf)    
    get :new, :project_id => @project1.id
    assert_response :forbidden    
    
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
  
  def test_create    
    assert_difference 'DmsfLink.count', +1 do    
      post :create, :dmsf_link => {
        :project_id => @project1.id, 
        :target_project_id => @project1.id,
        :dmsf_folder_id => @folder1.id,
        :target_file_id => @file1.id,
        :name => 'file_link'
        }
    end    
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
  
  def test_destroy      
    assert_difference 'DmsfLink.count', -1 do
      delete :destroy, :project_id => @project1.id, :id => @file_link.id
    end
    assert_redirected_to dmsf_folder_path(:id => @project1.id, :folder_id => @folder1.id)
  end
end