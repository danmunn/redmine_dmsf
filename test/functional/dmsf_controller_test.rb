# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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

  fixtures :users, :email_addresses, :dmsf_folders, :custom_fields,
    :custom_values, :projects, :roles, :members, :member_roles, :dmsf_links,
    :dmsf_files, :dmsf_file_revisions, :dmsf_folder_permissions, :dmsf_locks

  def setup
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
    @folder7 = DmsfFolder.find_by_id 7
    @manager = User.find_by_id 2 #1
    User.current = nil
    @request.session[:user_id] = @manager.id
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
    assert_kind_of User, @manager
  end

  def test_edit_folder_forbidden
    # Missing permissions
    get :edit, :id => @project, :folder_id => @folder1
    assert_response :forbidden
  end

  def test_edit_folder_allowed
    # Permissions OK
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    get :edit, :id => @project, :folder_id => @folder1
    assert_response :success
    assert_select 'label', { :text => @custom_field.name }
    assert_select 'option', { :value => @custom_value.value }
  end

  def test_trash_forbidden
    # Missing permissions
    get :trash, :id => @project
    assert_response :forbidden
  end

  def test_trash_allowed
    # Permissions OK
    @role.add_permission! :file_delete
    get :trash, :id => @project
    assert_response :success
    assert_select 'h2', { :text => l(:link_trash_bin) }
  end

  def test_delete_forbidden
    # Missing permissions
    get :delete, :id => @project, :folder_id => @folder1.id, :commit => false
    assert_response :forbidden
  end

  def test_delete_not_empty
    # Permissions OK but the folder is not empty
    @role.add_permission! :folder_manipulation
    get :delete, :id => @project, :folder_id => @folder1.id, :commit => false
    assert_response :redirect
    assert_include l(:error_folder_is_not_empty), flash[:error]
  end

  def test_delete_locked
    # Permissions OK but the folder is locked
    @role.add_permission! :folder_manipulation
    get :delete, :id => @project, :folder_id => @folder2.id, :commit => false
    assert_response :redirect
    assert_include l(:error_folder_is_locked), flash[:error]
  end

  def test_delete_ok
    # Empty and not locked folder
    @role.add_permission! :folder_manipulation
    get :delete, :id => @project, :folder_id => @folder4.id, :commit => false
    assert_response :redirect
  end

  def test_restore_forbidden
    # Missing permissions
    @folder4.deleted = 1
    @folder4.save
    get :restore, :id => @project, :folder_id => @folder4.id
    assert_response :forbidden
  end

  def test_restore_ok
    # Permissions OK
    @request.env['HTTP_REFERER'] = trash_dmsf_path(:id => @project.id)
    @role.add_permission! :folder_manipulation
    @folder4.deleted = 1
    @folder4.save
    get :restore, :id => @project, :folder_id => @folder4.id
    assert_response :redirect
  end

  def test_delete_restore_entries_forbidden
    # Missing permissions
    get :entries_operation, :id => @project, :delete_entries => 'Delete',
        :ids => ["folder-#{@folder1.id}", "file-#{@file1.id}", "folder-link-#{@folder_link1.id}", "file-link-#{@file_link2.id}"]
    assert_response :forbidden
  end

  def test_delete_restore_not_empty
    # Permissions OK but the folder is not empty
    @request.env['HTTP_REFERER'] = dmsf_folder_path(:id => @project.id)
    @role.add_permission! :view_dmsf_files
    get :entries_operation, :id => @project, :delete_entries => 'Delete',
      :ids => ["folder-#{@folder1.id}", "file-#{@file1.id}", "folder-link-#{@folder_link1.id}", "file-link-#{@file_link2.id}"]
    assert_response :redirect
    assert_equal flash[:error].to_s, l(:error_folder_is_not_empty)
  end

  def test_delete_restore_entries_ok
    # Permissions OK
    @request.env['HTTP_REFERER'] = dmsf_folder_path(:id => @project.id)
    @role.add_permission! :view_dmsf_files
    flash[:error] = nil
    get :entries_operation, :id => @project, :delete_entries => 'Delete',
        :ids => ["file-#{@file1.id}", "file-link-#{@file_link2.id}"]
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_restore_entries
    # Restore
    @role.add_permission! :view_dmsf_files
    @request.env['HTTP_REFERER'] = trash_dmsf_path(:id => @project.id)
    get :entries_operation, :id => @project, :restore_entries => 'Restore',
        :ids => ["file-#{@file1.id}", "file-link-#{@file_link2.id}"]
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_show
    @role.add_permission! :view_dmsf_files
    @role.add_permission! :view_dmsf_folders
    get :show, :id => @project.id
    assert_response :success
    assert_select 'tr.dmsf_tree', :count => 0
  end

  def test_show_tag
    @role.add_permission! :view_dmsf_files
    @role.add_permission! :view_dmsf_folders
    get :show, :id => @project.id, :custom_field_id => 21, :custom_value => 'Technical documentation'
    assert_response :success
    assert_select 'tr.dmsf_tree', :count => 0
  end

  def test_show_tree_view
    @role.add_permission! :view_dmsf_files
    @role.add_permission! :view_dmsf_folders
    @manager.pref[:dmsf_tree_view] = '1'
    @manager.preference.save
    get :show, :id => @project.id
    assert_response :success
    assert_select 'tr.dmsf_tree'
  end

  def test_show_csv
    @role.add_permission! :view_dmsf_files
    @role.add_permission! :view_dmsf_folders
    get :show, :id => @project.id, :format => 'csv', :settings => {:dmsf_columns => ['id', 'title']}
    assert_response :success
    assert_equal 'text/csv; header=present', @response.content_type
  end

  def test_new_forbidden
    @role.remove_permission! :folder_manipulation
    get :new, :id => @project, :parent_id => nil
    assert_response :forbidden
  end

  def test_new_forbidden
    @role.add_permission! :folder_manipulation
    get :new, :id => @project, :parent_id => nil
    assert_response :success
  end

  def test_email_entries_email_from
    Setting.plugin_redmine_dmsf['dmsf_documents_email_from'] = 'karel.picman@kontron.com'
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.expand_path '../../fixtures/files', __FILE__
    @role.add_permission! :view_dmsf_files
    get :entries_operation, :id => @project, :email_entries => 'Email', :ids => ["file-#{@file1.id}"]
    assert_response :success
    assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_from']
  end

  def test_email_entries_reply_to
    Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to'] = 'karel.picman@kontron.com'
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.expand_path '../../fixtures/files', __FILE__
    @role.add_permission! :view_dmsf_files
    get :entries_operation, :id => @project, :email_entries => 'Email', :ids => ["file-#{@file1.id}"]
    assert_response :success
    assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to']
  end

  def test_email_entries_links_only
    Setting.plugin_redmine_dmsf['dmsf_documents_email_links_only'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.expand_path '../../fixtures/files', __FILE__
    @role.add_permission! :view_dmsf_files
    get :entries_operation, :id => @project, :email_entries => 'Email', :ids => ["file-#{@file1.id}"]
    assert_response :success
    assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_links_only']
  end

  def test_add_email_forbidden
    xhr :get, :add_email, id: @project.id
    assert_response :forbidden
  end

  def test_add_email
    @role.add_permission! :view_dmsf_files
    xhr :get, :add_email, id: @project.id
    assert_response :success
  end

  def test_append_email_forbidden
    post :append_email, :id => @project, :user_ids => @project.members.collect{ |m| m.user.id }, :format => 'js'
    assert_response :forbidden
  end

  def test_append_email_forbidden
    @role.add_permission! :view_dmsf_files
    post :append_email, :id => @project, :user_ids => @project.members.collect{ |m| m.user.id }, :format => 'js'
    assert_response :success
  end

  def test_autocomplete_for_user_forbidden
    xhr :get, :autocomplete_for_user, id: @project.id
    assert_response :forbidden
  end

  def test_autocomplete_for_user
    @role.add_permission! :view_dmsf_files
    xhr :get, :autocomplete_for_user, id: @project
    assert_response :success
  end

  def test_create_folder_in_root
    @role.add_permission! :folder_manipulation
    @role.add_permission! :view_dmsf_folders
    assert_difference 'DmsfFolder.count', +1 do
      post :create, :id => @project.id, :dmsf_folder => {
        :title => 'New folder',
        :description => 'Unit tests'
      }
    end
    assert_redirected_to dmsf_folder_path(:id => @project, :folder_id => nil)
  end

  def test_create_folder
    @role.add_permission! :folder_manipulation
    @role.add_permission! :view_dmsf_folders
    assert_difference 'DmsfFolder.count', +1 do
      post :create, :id => @project.id, :parent_id => @folder1.id, :dmsf_folder => {
        :title => 'New folder',
        :description => 'Unit tests'
      }
    end
    assert_redirected_to dmsf_folder_path(:id => @project, :folder_id => @folder1)
  end

end