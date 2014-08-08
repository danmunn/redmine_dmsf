# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-14 Karel Pičman <karel.picman@kontron.com>
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

class DmsfControllerTest < RedmineDmsf::Test::TestCase  
  include Redmine::I18n  
    
  fixtures :users, :dmsf_folders, :custom_fields, :custom_values, :projects, 
    :roles, :members, :member_roles, :dmsf_links, :dmsf_files, :dmsf_file_revisions

  def setup
    @request.session[:user_id] = 2
    @project = Project.find_by_id 1
    assert_not_nil @project
    @project.enable_module! :dmsf
    @folder1 = DmsfFolder.find_by_id 1
    @folder2 = DmsfFolder.find_by_id 2
    @folder4 = DmsfFolder.find_by_id 4
    @file1 = DmsfFile.find_by_id 1
    @file_link2 = DmsfLink.find_by_id 4
    @folder_link1 = DmsfLink.find_by_id 1
    @role = Role.find_by_id 1
    @custom_field = CustomField.find_by_id 21
    @custom_value = CustomValue.find_by_id 21
    @user1 = User.find_by_id 1
    User.current = @user1
  end
  
  def test_truth
    assert_kind_of Project, @project
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder2
    assert_kind_of DmsfFolder, @folder4
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfLink, @file_link2
    assert_kind_of DmsfLink, @folder_link1
    assert_kind_of Role, @role
    assert_kind_of CustomField, @custom_field
    assert_kind_of CustomValue, @custom_value
    assert_kind_of User, @user1    
  end
    
  def test_edit_folder
    # Missing permissions
    get :edit, :id => @project, :folder_id => @folder1
    assert_response 403    
    
    # Permissions OK
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    get :edit, :id => @project, :folder_id => @folder1
    assert_response :success
    assert_select 'label', { :text => @custom_field.name }
    assert_select 'option', { :value => @custom_value.value }
  end
  
  def test_trash
    # Missing permissions
    get :trash, :id => @project
    assert_response 403
    
    # Permissions OK
    @role.add_permission! :file_delete    
    get :trash, :id => @project
    assert_response :success
    assert_select 'h2', { :text => l(:link_trash_bin) }
  end
  
  def test_delete
    # Missing permissions
    get :delete, :id => @project, :folder_id => @folder1.id, :commit => false
    assert_response 403
        
    # Permissions OK but the folder is not empty
    @role.add_permission! :folder_manipulation    
    get :delete, :id => @project, :folder_id => @folder1.id, :commit => false
    assert_response :redirect    
    assert_include l(:error_folder_is_not_empty), flash[:error]
    
    # Permissions OK but the folder is locked    
    get :delete, :id => @project, :folder_id => @folder2.id, :commit => false
    assert_response :redirect    
    assert_include l(:error_folder_is_locked), flash[:error]
    
    # Empty and not locked folder
    flash[:error].clear   
    get :delete, :id => @project, :folder_id => @folder4.id, :commit => false
    assert_response :redirect     
    assert_equal 0, flash[:error].size
  end
  
  def test_restore
    @role.add_permission! :folder_manipulation    
    get :delete, :id => @project, :folder_id => @folder4.id
    assert_response :redirect     
    
    # Missing permissions
    @role.remove_permission! :folder_manipulation    
    get :restore, :id => @project, :folder_id => @folder4.id
    assert_response 403
    
    # Permissions OK
    @request.env['HTTP_REFERER'] = trash_dmsf_path(:id => @project.id)
    @role.add_permission! :folder_manipulation    
    get :restore, :id => @project, :folder_id => @folder4.id
    assert_response :redirect     
  end
  
  def test_delete_restore_entries    
    # Missing permissions
    get :entries_operation, :id => @project, :delete_entries => 'Delete', 
      :subfolders => [@folder1.id.to_s], :files => [@file1.id.to_s], 
      :dir_links => [@folder_link1.id.to_s], :file_links => [@file_link2.id.to_s]
    assert_response :forbidden   
    
    # Permissions OK but the folder is not empty    
    @request.env['HTTP_REFERER'] = dmsf_folder_path(:id => @project.id)
    @role.add_permission! :folder_manipulation
    @role.add_permission! :view_dmsf_files
    get :entries_operation, :id => @project, :delete_entries => 'Delete', 
      :subfolders => [@folder1.id.to_s], :files => [@file1.id.to_s], 
      :dir_links => [@folder_link1.id.to_s], :file_links => [@file_link2.id.to_s]
    assert_response :redirect
    assert_equal flash[:error].to_s, l(:error_folder_is_not_empty)
    
    # Permissions OK
    flash[:error] = nil
    get :entries_operation, :id => @project, :delete_entries => 'Delete', 
      :subfolders => [], :files => [@file1.id.to_s], 
      :dir_links => [], :file_links => [@file_link2.id.to_s]
    assert_response :redirect
    assert_nil flash[:error]
    
    # Restore
    @request.env['HTTP_REFERER'] = trash_dmsf_path(:id => @project.id)    
    get :entries_operation, :id => @project, :restore_entries => 'Restore', 
      :subfolders => [], :files => [@file1.id.to_s], 
      :dir_links => [], :file_links => [@file_link2.id.to_s]
    assert_response :redirect
    assert_nil flash[:error]
  end
  
end