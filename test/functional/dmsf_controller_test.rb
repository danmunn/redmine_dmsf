# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# DMSF controller
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
    default_url_options[:host] = 'www.example.com'
  end

  def test_edit_folder_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    get "/projects/#{@project1.id}/dmsf/edit", params: { folder_id: @folder1 }
    assert_response :forbidden
  end

  def test_edit_folder_allowed
    # Permissions OK
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf/edit", params: { folder_id: @folder1.id }
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
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/save",
         params: { folder_id: @folder2.id, parent_id: @folder2.dmsf_folder.id,
                   dmsf_folder: { title: @folder2.title, description: 'Updated folder' } }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder2.dmsf_folder.id)
  end

  def test_edit_folder_redirection_to_the_same_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/save",
         params: { folder_id: @folder2.id, parent_id: @folder2.dmsf_folder.id,
                   dmsf_folder: { title: @folder2.title, description: 'Updated folder',
                                  redirect_to_folder_id: @folder2.id } }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder2.id)
  end

  def test_trash_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_delete
    get "/projects/#{@project1.id}/dmsf/trash"
    assert_response :forbidden
  end

  def test_trash_allowed
    # Permissions OK
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf/trash"
    assert_response :success
    assert_select 'h2', { text: l(:link_trash_bin) }
  end

  def test_trash
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @folder1.delete commit: false
    get "/projects/#{@project1.id}/dmsf/trash"
    assert_response :success
    assert_select 'a', href:  dmsf_folder_path(id: @folder1.project, folder_id: @folder1.id)
    assert_select 'a', href:  dmsf_folder_path(id: @folder2.project, folder_id: @folder2.id)
    assert_select 'a', href: url_for(controller: :dmsf_files, action: 'view', id: @file4.id, only_path: true)
    assert_select 'a', href: url_for(controller: :dmsf_files, action: 'view', id: @link2.target_id, only_path: true)
  end

  def test_empty_trash
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf/empty_trash"
    assert_equal 0, DmsfFolder.deleted.where(project_id: @project1.id).all.size
    assert_equal 0, DmsfFile.deleted.where(project_id: @project1.id).all.size
    assert_equal 0, DmsfLink.deleted.where(project_id: @project1.id).all.size
    assert_redirected_to trash_dmsf_path(id: @project1)
  end

  def test_empty_trash_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_delete
    get "/projects/#{@project1.id}/dmsf/empty_trash"
    assert_response :forbidden
  end

  def test_delete_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    delete "/projects/#{@project1.id}/dmsf/delete", params: { folder_id: @folder1.id, commit: false }
    assert_response :forbidden
  end

  def test_delete_locked
    # Permissions OK but the folder is locked
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1, folder_id: @folder2.id)
    delete "/projects/#{@project1.id}/dmsf/delete", params: { folder_id: @folder2.id, commit: false }
    assert_response :redirect
    assert_include l(:error_folder_is_locked), flash[:error]
  end

  def test_delete_ok
    # Empty and not locked folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1)
    delete "/projects/#{@project1.id}/dmsf/delete",
           params: { folder_id: @folder1.id, commit: false }
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_delete_subfolder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1, folder_id: @folder1.id)
    delete "/projects/#{@folder2.project.id}/dmsf/delete",
           params: { folder_id: @folder2.id, parent_id: @folder1.id, commit: false }
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.id)
  end

  def test_restore_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_developer.remove_permission! :folder_manipulation
    @folder4.deleted = 1
    @folder4.save
    get "/projects/#{@folder4.project.id}/dmsf/restore", params: { folder_id: @folder4.id }
    assert_response :forbidden
  end

  def test_restore_ok
    # Permissions OK
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = trash_dmsf_path(id: @project1)
    @folder1.deleted = 1
    @folder1.save
    get "/projects/#{@project1.id}/dmsf/restore", params: { folder_id: @folder1.id }
    assert_response :redirect
  end

  def test_delete_entries_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { delete_entries: true,
                   ids: ["folder-#{@folder1.id}", "file-#{@file1.id}", "folder-link-#{@link1.id}",
                         "file-link-#{@link2.id}"] }
    assert_response :forbidden
  end

  def test_delete_entries_ok
    # Permissions OK
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = dmsf_folder_path(id: @project1)
    flash[:error] = nil
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { delete_entries: true, ids: ["folder-#{@folder7.id}", "file-#{@file1.id}", "file-link-#{@link2.id}"] }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_restore_entries
    # Restore
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = trash_dmsf_path(id: @project1)
    flash[:error] = nil
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { restore_entries: true, ids: ["file-#{@file1.id}", "file-link-#{@link2.id}"] }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_show
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_WRITE' } do
      get "/projects/#{@project1.id}/dmsf"
      assert_response :success
      # New file link
      assert_select 'a[href$=?]', '/dmsf/upload/multi_upload'
      # New folder link
      assert_select 'a[href$=?]', '/dmsf/new'
      # Filters
      assert_select 'fieldset#filters'
      # Options
      assert_select 'fieldset#options'
      # Options - no "Group by"
      assert_select 'select#group_by', count: 0
      # The main table
      assert_select 'table.dmsf'
      # CSV export
      assert_select 'a.csv'
      # WebDAV
      assert_select 'a.webdav', text: 'WebDAV'
      # 'Zero Size File' document and an expander is present
      assert_select 'a', text: @file10.title
      assert_select 'span.dmsf-expander'
    end
  end

  def test_show_webdav_disabled
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => nil } do
      get "/projects/#{@project1.id}/dmsf"
      assert_response :success
      assert_select 'a.webdav', text: 'WebDAV', count: 0
    end
  end

  def test_show_filters_found
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf", params: { f: ['title'], op: { 'title' => '~' }, v: { 'title' => ['Zero'] } }
    assert_response :success
    # 'Zero Size File' document
    assert_select 'a', text: @file10.title
    # No expander if a filter is set
    assert_select 'span.dmsf-expander', count: 0
  end

  def test_show_filters_not_found
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf", params: { f: ['title'], op: { 'title' => '~' }, v: { 'title' => ['xxx'] } }
    assert_response :success
    # 'Zero Size File' document
    assert_select 'a', text: @file10.title, count: 0
  end

  def test_show_filters_custom_field
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf",
        params: { set_filter: '1', f: ['cf_21', ''], op: { 'cf_21' => '=' }, v: { 'cf_21' => ['User documentation'] } }
    assert_response :success
    # Folder 1 with Tag=User documentation
    assert_select 'a', text: @folder1.title
    # Other document/folders are not present
    assert_select 'a', text: @file10.title, count: 0
  end

  def test_show_without_file_manipulation
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_manipulation
    get "/projects/#{@project1.id}/dmsf"
    assert_response :success
    # New file link should be missing
    assert_select 'a[href$=?]', '/dmsf/upload/multi_upload', count: 0
  end

  def test_show_csv
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf", params: { format: 'csv' }
    assert_response :success
    assert @response.media_type.include?('text/csv')
  end

  def test_show_folder_doesnt_correspond_the_project
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert @project1 != @folder3.project
    get "/projects/#{@project1.id}/dmsf", params: { folder_id: @folder3.id }
    assert_response :not_found
  end

  def test_folder_link_to_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@link1.project_id}/dmsf", params: { folder_id: @link1.dmsf_folder_id }
    assert_response :success
    assert_select 'a', text: @link1.title, count: 1
    assert_select 'a[href$=?]',
                  "/projects/#{@link1.target_project.identifier}/dmsf?folder_id=#{@link1.target_folder.id}",
                  count: 2 # Two because of folder1 and folder1_link
  end

  def test_folder_link_to_project
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @link1.target_project_id = @project2.id
    @link1.target_id = nil
    assert @link1.save
    get "/projects/#{@link1.project_id}/dmsf", params: { folder_id: @link1.dmsf_folder_id }
    assert_response :success
    assert_select 'a', text: @link1.title, count: 1
    assert_select 'a[href$=?]', "/projects/#{@project2.identifier}/dmsf", count: 1
  end

  def test_new_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    get "/projects/#{@project1.id}/dmsf/new"
    assert_response :forbidden
  end

  def test_new
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf/new"
    assert_response :success
  end

  def test_email_entries_email_from_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :email_documents
    with_settings plugin_redmine_dmsf: { 'dmsf_documents_email_from' => 'karel.picman@kontron.com' } do
      post "/projects/#{@project1.id}/dmsf/entries", params: { email_entries: true, ids: ["file-#{@file1.id}"] }
      assert_response :forbidden
    end
  end

  def test_email_entries_email_from
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_documents_email_from' => 'karel.picman@kontron.com' } do
      post "/projects/#{@project1.id}/dmsf/entries", params: { email_entries: true, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_from']
    end
  end

  def test_email_entries_reply_to
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_documents_email_reply_to' => 'karel.picman@kontron.com' } do
      post "/projects/#{@project1.id}/dmsf/entries", params: { email_entries: true, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select "input:match('value', ?)", Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to']
    end
  end

  def test_email_entries_links_only
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_documents_email_links_only' => '1' } do
      post "/projects/#{@project1.id}/dmsf/entries", params: { email_entries: true, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'input[id=email_links_only][value=1]'
    end
  end

  def test_entries_email
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    zip_file = Tempfile.new('test', Rails.root.join('tmp'))
    post "/projects/#{@project1.id}/dmsf/entries/email",
         params: { email: { to: 'to@test.com', from: 'from@test.com', subject: 'subject', body: 'body',
                            expired_at: '2015-01-01', folders: [], files: [@file1.id],
                            zipped_content: zip_file.path } }
    assert_redirected_to dmsf_folder_path(id: @project1)
  ensure
    zip_file.unlink
  end

  def test_add_email_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :view_dmsf_files
    get '/projects/dmsf/add_email', params: { id: @project1.id }, xhr: true
    assert_response :forbidden
  end

  def test_add_email
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/add_email', params: { id: @project1.id }, xhr: true
    assert_response :success
  end

  def test_append_email_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :view_dmsf_files
    post '/projects/dmsf/append_email',
         params: { id: @project1.id, user_ids: @project1.members.collect { |m| m.user.id }, format: 'js' }
    assert_response :forbidden
  end

  def test_append_email
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post '/projects/dmsf/append_email',
         params: { id: @project1.id, user_ids: @project1.members.collect { |m| m.user.id }, format: 'js' }
    assert_response :success
  end

  def test_autocomplete_for_user_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :view_dmsf_files
    get '/projects/dmsf/autocomplete_for_user', params: { id: @project1.id }, xhr: true
    assert_response :forbidden
  end

  def test_autocomplete_for_user
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/autocomplete_for_user', params: { id: @project1.id }, xhr: true
    assert_response :success
  end

  def test_create_folder_in_root
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfFolder.count', +1 do
      post "/projects/#{@project1.id}/dmsf/create",
           params: { dmsf_folder: { title: 'New folder', description: 'Unit tests' } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: nil)
  end

  def test_create_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfFolder.count', +1 do
      post "/projects/#{@project1.id}/dmsf/create",
           params: { parent_id: @folder1.id, dmsf_folder: { title: 'New folder', description: 'Unit tests' } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1)
  end

  def test_show_with_sub_projects
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_projects_as_subfolders' => '1' } do
      get "/projects/#{@project1.id}/dmsf"
      assert_response :success
      # @project5 is as a sub-folder
      assert_select "tr##{@project5.id}pspan", count: 1
    end
  end

  def test_show_without_sub_projects
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf"
    assert_response :success
    # @project5 is not as a sub-folder
    assert_select "tr##{@project5.id}pspan", count: 0
  end

  def test_show_default_sort_column
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/dmsf"
    assert_response :success
    # The default column Title's header is displayed as sorted '^'
    assert_select 'a.icon-sorted-desc', text: l(:label_column_title)
  end

  def test_index
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf'
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
    post '/login', params: { username: 'dlopper', password: 'foo' }
    get '/dmsf'
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
    post '/login', params: { username: 'someone', password: 'foo' }
    get '/dmsf'
    assert_response :forbidden
  end

  def test_copymove_authorize_admin
    post '/login', params: { username: 'admin', password: 'admin' }
    get "/projects/#{@project1.id}/entries/copymove",
        params: { folder_id: @file1.dmsf_folder, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_template 'copymove'
  end

  def test_copymove_authorize_non_member
    post '/login', params: { username: 'someone', password: 'foo' }
    get "/projects/#{@project1.id}/entries/copymove",
        params: { folder_id: @file1.dmsf_folder, ids: ["file-#{@file1.id}"] }
    assert_response :forbidden
  end

  def test_copymove_authorize_member_no_module
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @file1.project.disable_module! :dmsf
    get "/projects/#{@project1.id}/entries/copymove",
        params: { folder_id: @file1.dmsf_folder, ids: ["file-#{@file1.id}"] }
    assert_response :forbidden
  end

  def test_copymove_authorize_forbidden
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    get "/projects/#{@project1.id}/entries/copymove",
        params: { folder_id: @file1.dmsf_folder, ids: ["file-#{@file1.id}"] }
    assert_response :forbidden
  end

  def test_copymove_target_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@project1.id}/entries/copymove",
        params: { folder_id: @file1.dmsf_folder, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_template 'copymove'
  end

  def test_entries_copy
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @folder1.project.id, target_folder_id: @folder1.id },
                   ids: ["file-#{@file1.id}"],
                   copy_entries: true }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_entries_copy_to_the_same_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @file1.project.id, target_folder_id: @file1.dmsf_folder },
                   ids: ["file-#{@file1.id}"],
                   copy_entries: true }
    assert_response :redirect
    assert_equal flash[:error], l(:error_target_folder_same)
  end

  def test_entries_move_recursion
    # Move a folder under the same folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @folder2.project.id, target_folder_id: @folder2.id },
                   ids: ["folder-#{@folder1.id}"],
                   move_entries: true }
    assert_response :redirect
    assert_equal flash[:error], l(:error_target_folder_same)
  end

  def test_entries_move_infinity
    # Move the folder to itself
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @folder2.project.id, target_folder_id: @folder2.id },
                   ids: ["folder-#{@folder2.id}"],
                   move_entries: true }
    assert_response :redirect
    assert_equal flash[:error], l(:error_target_folder_same)
  end

  def test_entries_copy_to_locked_folder
    post '/login', params: { username: 'admin', password: 'admin' }
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @folder2.project.id, target_folder_id: @folder2.id },
                   ids: ["file-#{@file1.id}"],
                   move_entries: true }
    assert_response :forbidden
  end

  def test_entries_copy_to_dmsf_not_enabled
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @project2.disable_module! :dmsf
    post "/projects/#{@project2.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @project2.id },
                   ids: ["file-#{@file1.id}"],
                   copy_entries: true }
    assert_response :forbidden
  end

  def test_entries_copy_to_dmsf_enabled
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project2.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @project2.id },
                   ids: ["file-#{@file1.id}"],
                   copy_entries: true }
    assert_response :redirect
  end

  def test_entries_copy_to_as_non_member
    post '/login', params: { username: 'someone', password: 'foo' }
    post "/projects/#{@project2.id}/dmsf/entries",
         params: { dmsf_entries: { target_project_id: @project2.id },
                   ids: ["file-#{@file1.id}"],
                   copy_entries: true }
    assert_response :forbidden
  end

  def test_copymove_new_fast_links_enabled
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    member = Member.find_by(user_id: @jsmith.id, project_id: @project1.id)
    assert member
    member.dmsf_fast_links = true
    member.save
    get "/projects/#{@project1.id}/entries/copymove",
        params: { folder_id: @file1.dmsf_folder, ids: ["file-#{@file4.id}"] }
    assert_response :success
    assert_select 'label', { count: 0, text: l(:label_target_project) }
    assert_select 'label', { count: 0, text: "#{l(:label_target_folder)}#" }
  end

  def test_entries_move_fast_links_enabled
    # Target project is not given
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post "/projects/#{@project1.id}/dmsf/entries",
         params: { dmsf_entries: { target_folder_id: @folder1.id },
                   ids: ["file-#{@file1.id}"],
                   move_entries: true }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_digest
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf/digest', xhr: true
    assert_response :success
  end

  def test_digest_unauthorized
    get '/dmsf/digest', xhr: true
    assert_response :unauthorized
  end

  def test_reset_digest
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    post '/dmsf/digest', params: { password: 'jsmith' }
    assert_response :redirect
    assert_redirected_to my_account_path
    token = Token.find_by(user_id: @jsmith.id, action: 'dmsf_webdav_digest')
    assert token
    assert_equal ActiveSupport::Digest.hexdigest("jsmith:#{RedmineDmsf::Webdav::AUTHENTICATION_REALM}:jsmith"),
                 token.value
  end

  def test_reset_digest_unauthorized
    post '/dmsf/digest', params: { password: 'jsmith' }
    assert_response :redirect
    assert_redirected_to 'http://www.example.com/login?back_url=http%3A%2F%2Fwww.example.com%2Fdmsf%2Fdigest'
  end
end
