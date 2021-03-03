# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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
  include Rails.application.routes.url_helpers

  fixtures :custom_fields, :custom_values, :dmsf_links, :dmsf_folder_permissions, :dmsf_locks,
           :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @link2 = DmsfLink.find 2
    @link1 = DmsfLink.find 1
    @custom_field = CustomField.find 21
    @custom_value = CustomValue.find 21
    User.current = nil
    @request.session[:user_id] = @jsmith.id
    default_url_options[:host] = 'http://example.com'
  end
  
  def test_edit_folder_forbidden
    # Missing permissions
    @role_manager.remove_permission! :folder_manipulation
    get :edit, params: { id: @project1, folder_id: @folder1 }
    assert_response :forbidden
  end

  def test_edit_folder_allowed
    # Permissions OK
    get :edit, params: { id: @project1, folder_id: @folder1}
    assert_response :success
    # Custom fields
    assert_select 'label', { text: @custom_field.name }
    assert_select 'option', { value: @custom_value.value }
    # Permissions - The form must contain a check box for each available role
    roles = []
    @project1.members.each do |m|
      roles << m.roles
    end
    roles.uniq.each do |r|
      assert_select 'input', { value: r.name }
    end
  end

  def test_edit_folder_redirection_to_the_parent_folder
    post :save, params: { id: @project1, folder_id: @folder2.id, parent_id: @folder2.dmsf_folder.id,
                          dmsf_folder: { title: @folder2.title, description: @folder2.description} }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder2.dmsf_folder.id)
  end

  def test_edit_folder_redirection_to_the_same_folder
    post :save, params: { id: @project1, folder_id: @folder2.id, parent_id: @folder2.dmsf_folder.id,
                          dmsf_folder: { title: @folder2.title, description: @folder2.description,
                                         redirect_to_folder_id: @folder2.id } }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder2.id)
  end

  def test_trash_forbidden
    # Missing permissions
    @role_manager.remove_permission! :file_delete
    get :trash, params: { id: @project1 }
    assert_response :forbidden
  end

  def test_trash_allowed
    # Permissions OK
    get :trash, params: { id: @project1 }
    assert_response :success
    assert_select 'h2', { text: l(:link_trash_bin) }
  end

  def test_trash
    @folder1.delete false
    get :trash, params: { id: @project1 }
    assert_response :success
    assert_select 'a', href:  dmsf_folder_path(id: @folder1.project.id, folder_id: @folder1.id)
    assert_select 'a', href:  dmsf_folder_path(id: @folder2.project.id, folder_id: @folder2.id)
    assert_select 'a', href: url_for(controller: :dmsf_files, action: 'view', id: @file4.id, only_path: true)
    assert_select 'a', href: url_for(controller: :dmsf_files, action: 'view', id: @link2.target_id, only_path: true)
  end

  def test_empty_trash
    get :empty_trash, params: { id: @project1.id }
    assert_equal 0, DmsfFolder.deleted.where(project_id: @project1.id).all.size
    assert_equal 0, DmsfFile.deleted.where(project_id: @project1.id).all.size
    assert_equal 0, DmsfLink.deleted.where(project_id: @project1.id).all.size
    assert_redirected_to trash_dmsf_path(id: @project1.id)
  end

  def test_empty_trash_forbidden
    # Missing permissions
    @role_manager.remove_permission! :file_delete
    get :empty_trash, params: { id: @project1.id }
    assert_response :forbidden
  end

  def test_delete_forbidden
    # Missing permissions
    @role_manager.remove_permission! :folder_manipulation
    get :delete, params: { id: @project1, folder_id: @folder1.id, commit: false }
    assert_response :forbidden
  end

  def test_delete_locked
    # Permissions OK but the folder is locked
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1.id, folder_id: @folder2.id)
    get :delete, params: { id: @project1, folder_id: @folder2.id, commit: false}
    assert_response :redirect
    assert_include l(:error_folder_is_locked), flash[:error]
  end

  def test_delete_ok
    # Empty and not locked folder
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1, folder_id: @folder1.dmsf_folder)
    get :delete, params: { id: @project1, folder_id: @folder1, parent_id: @folder1.dmsf_folder, commit: false }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.dmsf_folder)
  end

  def test_delete_subfolder
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1, folder_id: @folder2.dmsf_folder)
    get :delete, params: { id: @project1, folder_id: @folder2, parent_id: @folder2.dmsf_folder, commit: false }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder2.dmsf_folder)
  end

  def test_restore_forbidden
    # Missing permissions
    @role_developer.remove_permission! :folder_manipulation
    @folder4.deleted = 1
    @folder4.save
    get :restore, params: { id: @folder4.project.id, folder_id: @folder4.id }
    assert_response :forbidden
  end

  def test_restore_ok
    # Permissions OK
    @request.env['HTTP_REFERER'] = trash_dmsf_path(id: @project1.id)
    @folder1.deleted = 1
    @folder1.save
    get :restore, params: { id: @project1, folder_id: @folder1.id }
    assert_response :redirect
  end

  def test_delete_entries_forbidden
    # Missing permissions
    @role_manager.remove_permission! :folder_manipulation
    get :entries_operation, params: { id: @project1, delete_entries: 'Delete',
        ids: ["folder-#{@folder1.id}", "file-#{@file1.id}", "folder-link-#{@link1.id}", "file-link-#{@link2.id}"] }
    assert_response :forbidden
  end

  def test_delete_entries_ok
    # Permissions OK
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1.id)
    flash[:error] = nil
    get :entries_operation, params: { id: @project1, delete_entries: 'Delete',
        ids: ["folder-#{@folder7.id}", "file-#{@file1.id}", "file-link-#{@link2.id}"]}
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_restore_entries
    # Restore
    @request.env['HTTP_REFERER'] = trash_dmsf_path(id: @project1.id)
    flash[:error] = nil
    get :entries_operation, params: { id: @project1, restore_entries: 'Restore',
        ids: ["file-#{@file1.id}", "file-link-#{@link2.id}"]}
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_show
    get :show, params: { id: @project1.id }
    assert_response :success
    # New file link
    assert_select 'a[href$=?]', '/dmsf/upload/multi_upload'
    # New folder link
    assert_select 'a[href$=?]', '/dmsf/new'
    # Filters
    assert_select 'fieldset#filters'
    # Options
    assert_select 'fieldset#options'
    # The main table
    assert_select 'table.dmsf'
    # CSV export
    assert_select 'a.csv'
    # 'Zero Size File' document and an expander is present
    assert_select 'a', text: @file10.title
    assert_select 'span.dmsf_expander'
  end

  def test_show_filters_found
    get :show, params: { id: @project1.id, f: ['title'], op: { 'title' => '~' }, v: { 'title' => ['Zero'] } }
    assert_response :success
    # 'Zero Size File' document
    assert_select 'a', text: @file10.title
    # No expander if a filter is set
    assert_select 'span.dmsf_expander', count: 0
  end

  def test_show_filters_not_found
    get :show, params: { id: @project1.id, f: ['title'], op: { 'title' => '~' }, v: { 'title' => ['xxx'] } }
    assert_response :success
    # 'Zero Size File' document
    assert_select 'a', text: @file10.title, count: 0
  end

  def test_show_without_file_manipulation
    @role_manager.remove_permission! :file_manipulation
    get :show, params: { id: @project1.id }
    assert_response :success
    # New file link should be missing
    assert_select 'a[href$=?]', '/dmsf/upload/multi_upload', count: 0
  end

  def test_show_csv
    get :show, params: { id: @project1.id, format: 'csv' }
    assert_response :success
    assert @response.content_type.match?(/^text\/csv/)
  end

  def test_show_folder_doesnt_correspond_the_project
    # Despite the fact that project != @folder3.project
    assert @project1 != @folder3.project
    get :show, params: { id: @project1.id, folder_id: @folder3.id }
    assert_response :success
  end

  def test_new_forbidden
    @role_manager.remove_permission! :folder_manipulation
    get :new, params: { id: @project1, parent_id: nil }
    assert_response :forbidden
  end

  def test_new
    get :new, params: { id: @project1, parent_id: nil }
    assert_response :success
  end

  def test_email_entries_email_from_forbidden
    @role_manager.remove_permission! :email_documents
    with_settings plugin_redmine_dmsf: {'dmsf_documents_email_from' => 'karel.picman@kontron.com'} do
      get :entries_operation, params: {id: @project1, email_entries: 'Email', ids: ["file-#{@file1.id}"]}
      assert_response :forbidden
    end
  end

  def test_email_entries_email_from
    with_settings plugin_redmine_dmsf: {'dmsf_documents_email_from' => 'karel.picman@kontron.com'} do
      get :entries_operation, params: { id: @project1, email_entries: 'Email', ids: ["file-#{@file1.id}"]}
      assert_response :success
      assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_from']
    end
  end

  def test_email_entries_reply_to
    with_settings plugin_redmine_dmsf: {'dmsf_documents_email_reply_to' => 'karel.picman@kontron.com'} do
      get :entries_operation, params: { id: @project1, email_entries: 'Email', ids: ["file-#{@file1.id}"]}
      assert_response :success
      assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to']
    end
  end

  def test_email_entries_links_only
    with_settings plugin_redmine_dmsf: {'dmsf_documents_email_links_only' => '1'} do
      get :entries_operation, params: { id: @project1, email_entries: 'Email', ids: ["file-#{@file1.id}"]}
      assert_response :success
      assert_select "input[id=email_links_only][value=1]"
    end
  end

  def test_entries_email
    zip_file = Tempfile.new('test', DmsfHelper::temp_dir)
    get :entries_email, params:  { id: @project1, email:
        {
          to: 'to@test.com', from: 'from@test.com', subject: 'subject', body: 'body', expired_at: '2015-01-01',
          folders: [], files: [@file1.id], zipped_content: zip_file.path
        }
    }
    assert_redirected_to dmsf_folder_path(id: @project1)
  ensure
    zip_file.unlink
  end

  def test_add_email_forbidden
    @role_manager.remove_permission! :view_dmsf_files
    get :add_email, params: { id: @project1.id }, xhr: true
    assert_response :forbidden
  end

  def test_add_email
    get :add_email, params: { id: @project1.id }, xhr: true
    assert_response :success
  end

  def test_append_email_forbidden
    @role_manager.remove_permission! :view_dmsf_files
    post :append_email, params: { id: @project1, user_ids: @project1.members.collect{ |m| m.user.id }, format: 'js'}
    assert_response :forbidden
  end

  def test_append_email
    post :append_email, params: { id: @project1, user_ids: @project1.members.collect{ |m| m.user.id }, format: 'js'}
    assert_response :success
  end

  def test_autocomplete_for_user_forbidden
    @role_manager.remove_permission! :view_dmsf_files
    get :autocomplete_for_user, params: { id: @project1.id }, xhr: true
    assert_response :forbidden
  end

  def test_autocomplete_for_user
    get :autocomplete_for_user, params: { id: @project1 }, xhr: true
    assert_response :success
  end

  def test_create_folder_in_root
    assert_difference 'DmsfFolder.count', +1 do
      post :create, params: { id: @project1.id, dmsf_folder: { title: 'New folder', description: 'Unit tests' } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: nil)
  end

  def test_create_folder
    assert_difference 'DmsfFolder.count', +1 do
      post :create, params: { id: @project1.id, parent_id: @folder1.id,
                              dmsf_folder: { title: 'New folder', description: 'Unit tests' } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1)
  end

  def test_show_with_sub_projects
    with_settings plugin_redmine_dmsf: {'dmsf_projects_as_subfolders' => '1'} do
      get :show, params: { id: @project1.id }
      assert_response :success
      # @project3 is as a sub-folder
      assert_select "tr##{@project3.id}pspan", count: 1
    end
  end

  def test_show_without_sub_projects
    get :show, params: { id: @project1.id }
    assert_response :success
    # @project3 is not as a sub-folder
    assert_select "tr##{@project3.id}pspan", count: 0
  end

  def test_index
    get :index
    assert_response :success
    # Projects
    assert_select 'table.dmsf' do
      assert_select 'tr' do
        assert_select 'td.dmsf-title' do
          assert_select 'a', text: "[#{@project1.name}]"
          assert_select 'a', text: "[#{@project2.name}]"
        end
      end
    end
    # No context menu
    assert_select 'div.contextual', count: 0
    # No description
    assert_select 'div.dmsf-header', count: 0
    # No CSV export
    assert_select 'a.csv', count: 0
  end

  def test_index_non_member
    @request.session[:user_id] = @dlopper.id
    get :index
    assert_response :success
    assert_select 'table.dmsf' do
      assert_select 'tr' do
        assert_select 'td.dmsf-title' do
          assert_select 'a', text: "[#{@project1.name}]"
          assert_select 'a', text: "[#{@project2.name}]", count: 0
        end
      end
    end
  end

  def test_index_no_membership
    @request.session[:user_id] = @someone.id
    get :index
    assert_response :forbidden
  end

end