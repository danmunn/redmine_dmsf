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

# Context menu controller
class DmsfContextMenusControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_links, :dmsf_locks

  def setup
    super
    @file_link2 = DmsfLink.find 2
    @file_link6 = DmsfLink.find 6
    @folder_link1 = DmsfLink.find 1
    @url_link5 = DmsfLink.find 5
  end

  def test_dmsf_file
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_WRITE' } do
        get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
        assert_response :success
        assert_select 'a.icon-edit', text: l(:button_edit)
        assert_select 'a.icon-lock', text: l(:button_lock)
        assert_select 'a.icon-email-add', text: l(:label_notifications_on)
        assert_select 'a.icon-del', text: l(:button_delete)
        assert_select 'a.icon-download', text: l(:button_download)
        assert_select 'a.icon-email', text: l(:field_mail)
        assert_select 'a.icon-file', text: l(:button_edit_content)
      end
    end
  end

  def test_dmsf_file_locked
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_WRITE' } do
        get '/projects/dmsf/context_menu', params: { id: @file2.project.id, ids: ["file-#{@file2.id}"] }
        assert_response :success
        assert_select 'a.icon-edit.disabled', text: l(:button_edit)
        assert_select 'a.icon-unlock', text: l(:button_unlock)
        assert_select 'a.icon-lock', text: l(:button_lock), count: 0
        assert_select 'a.icon-email-add.disabled', text: l(:label_notifications_on)
        assert_select 'a.icon-del.disabled', text: l(:button_delete)
        assert_select 'a.icon-file.disabled', text: l(:button_edit_content)
      end
    end
  end

  def test_dmsf_edit_file_locked_by_myself
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    User.current = @jsmith
    @file1.lock!
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_WRITE' } do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_select 'a.icon-unlock', text: l(:button_unlock)
      assert_select 'a.icon-unlock.disabled', text: l(:button_edit_content), count: 0
      assert_select 'a.icon-file', text: l(:button_edit_content)
      assert_select 'a.icon-file.disabled', text: l(:button_edit_content), count: 0
    end
  end

  def test_dmsf_file_locked_force_unlock_permission_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { id: @file2.project.id, ids: ["file-#{@file2.id}"] }
    assert_response :success
    assert_select 'a.icon-unlock.disabled', text: l(:button_unlock)
  end

  def test_dmsf_file_locked_force_unlock_permission_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_developer.add_permission! :force_file_unlock
    get '/projects/dmsf/context_menu', params: { id: @file2.project.id, ids: ["file-#{@file2.id}"] }
    assert_response :success
    assert_select 'a.icon-unlock.disabled', text: l(:button_unlock), count: 0
  end

  def test_dmsf_file_notification_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @file1.notify_activate
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'a.icon-email', text: l(:label_notifications_off)
      assert_select 'a.icon-email-add', text: l(:label_notifications_on), count: 0
    end
  end

  def test_dmsf_file_manipulation_permission_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_manipulation
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'a.icon-edit.disabled', text: l(:button_edit)
      assert_select 'a.icon-lock.disabled', text: l(:button_lock)
      assert_select 'a.icon-email-add.disabled', text: l(:label_notifications_on)
      assert_select 'a.icon-del.disabled', text: l(:button_delete)
    end
  end

  def test_dmsf_file_manipulation_permission_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'a:not(icon-edit.disabled)', text: l(:button_edit)
      assert_select 'a:not(icon-lock.disabled)', text: l(:button_lock)
      assert_select 'a:not(icon-email-add.disabled)', text: l(:label_notifications_on)
      assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
    end
  end

  def test_dmsf_file_email_permission_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :email_documents
    get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-email.disabled', text: l(:field_mail)
  end

  def test_dmsf_file_email_permission_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :email_document
    get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a:not(icon-email.disabled)', text: l(:field_mail)
  end

  def test_dmsf_file_delete_permission_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_manipulation
    get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-del.disabled', text: l(:button_delete)
  end

  def test_dmsf_file_delete_permission_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
    assert_select 'a.icon-del', text: l(:button_delete)
  end

  def test_dmsf_file_edit_content
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_WRITE' } do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'a.dmsf-icon-file', text: l(:button_edit_content)
    end
  end

  def test_dmsf_file_edit_content_webdav_disabled
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => nil } do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'a:not(dmsf-icon-file)'
    end
  end

  def test_dmsf_file_edit_content_webdav_readonly
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_ONLY' } do
      get '/projects/dmsf/context_menu', params: { id: @file1.project.id, ids: ["file-#{@file1.id}"] }
      assert_response :success
      assert_select 'a.dmsf-icon-file.disabled', text: l(:button_edit_content)
    end
  end

  def test_dmsf_file_watch
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { id: @file1.project, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-fav-off', text: l(:button_watch)
  end

  def test_dmsf_file_unwatch
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @file1.add_watcher @jsmith
    get '/projects/dmsf/context_menu', params: { id: @file1.project, ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-fav', text: l(:button_unwatch)
  end

  def test_dmsf_file_link
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => '1', 'dmsf_webdav_strategy' => 'WEBDAV_READ_WRITE' } do
        get '/projects/dmsf/context_menu',
            params: { id: @file_link6.project.id, folder_id: @file_link6.dmsf_folder,
                      ids: ["file-link-#{@file_link6.id}"] }
        assert_response :success
        assert_select 'a.icon-edit', text: l(:button_edit)
        assert_select 'a.icon-lock', text: l(:button_lock)
        assert_select 'a.icon-email-add', text: l(:label_notifications_on)
        assert_select 'a.icon-del', text: l(:button_delete)
        assert_select 'a.icon-download', text: l(:button_download)
        assert_select 'a.icon-email', text: l(:field_mail)
        assert_select 'a.icon-file', text: l(:button_edit_content)
      end
    end
  end

  def test_dmsf_file_link_locked
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert @file_link2.target_file.locked?
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu',
          params: { id: @file_link2.project.id, folder_id: @file_link2.dmsf_folder.id,
                    ids: ["file-link-#{@file_link2.id}"] }
      assert_response :success
      assert_select 'a.icon-edit.disabled', text: l(:button_edit)
      assert_select 'a.icon-unlock', text: l(:button_unlock)
      assert_select 'a.icon-lock', text: l(:button_lock), count: 0
      assert_select 'a.icon-email-add.disabled', text: l(:label_notifications_on)
      assert_select 'a.icon-del', text: l(:button_delete)
    end
  end

  def test_dmsf_url_link
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get :'/projects/dmsf/context_menu', params: { id: @url_link5.project.id, ids: ["url-link-#{@url_link5.id}"] }
    assert_response :success
    assert_select 'a.icon-del', text: l(:button_delete)
  end

  def test_dmsf_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder1.project.id, ids: ["folder-#{@folder1.id}"] }
      assert_response :success
      assert_select 'a.icon-edit', text: l(:button_edit)
      assert_select 'a.icon-lock', text: l(:button_lock)
      assert_select 'a.icon-email-add', text: l(:label_notifications_on)
      assert_select 'a.icon-del', text: l(:button_delete)
      assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
      assert_select 'a.icon-download', text: l(:button_download)
      assert_select 'a.icon-email', text: l(:field_mail)
    end
  end

  def test_dmsf_folder_locked
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert @folder5.locked?
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder5.project.id, ids: ["folder-#{@folder5.id}"] }
      assert_response :success
      assert_select 'a.icon-edit.disabled', text: l(:button_edit)
      assert_select 'a.icon-unlock', text: l(:button_unlock)
      assert_select 'a.icon-lock', text: l(:button_lock), count: 0
      assert_select 'a.icon-email-add.disabled', text: l(:label_notifications_on)
      assert_select 'a.icon-del.disabled', text: l(:button_delete)
    end
  end

  def test_dmsf_folder_locked_force_unlock_permission_off
    post '/login', params: { username: 'dlopper', password: 'foo' }
    get '/projects/dmsf/context_menu', params: { id: @folder2.project.id, ids: ["folder-#{@folder2.id}"] }
    assert_response :success
    # @folder2 is locked by @jsmith, therefore @dlopper can't unlock it
    assert_select 'a.icon-unlock.disabled', text: l(:button_unlock)
  end

  def test_dmsf_folder_locked_force_unlock_permission_om
    post '/login', params: { username: 'dlopper', password: 'foo' }
    @role_developer.add_permission! :force_file_unlock
    get '/projects/dmsf/context_menu', params: { id: @folder2.project.id, ids: ["folder-#{@folder2.id}"] }
    assert_response :success
    # @folder2 is locked by @jsmith, but @dlopper can unlock it
    assert_select 'a.icon-unlock.disabled', text: l(:button_unlock), count: 0
  end

  def test_dmsf_folder_notification_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @folder5.notify_activate
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder5.project.id, ids: ["folder-#{@folder5.id}"] }
      assert_response :success
      assert_select 'a.icon-email', text: l(:label_notifications_off)
      assert_select 'a.icon-email-add', text: l(:label_notifications_on), count: 0
    end
  end

  def test_dmsf_folder_manipulation_permmissions_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder1.project.id, ids: ["folder-#{@folder1.id}"] }
      assert_response :success
      assert_select 'a.icon-edit.disabled', text: l(:button_edit)
      assert_select 'a.icon-lock.disabled', text: l(:button_lock)
      assert_select 'a.icon-email-add.disabled', text: l(:label_notifications_on)
      assert_select 'a.icon-del.disabled', text: l(:button_delete)
    end
  end

  def test_dmsf_folder_manipulation_permmissions_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder1.project.id, ids: ["folder-#{@folder1.id}"] }
      assert_response :success
      assert_select 'a:not(icon-edit.disabled)', text: l(:button_edit)
      assert_select 'a:not(icon-lock.disabled)', text: l(:button_lock)
      assert_select 'a:not(icon-email-add.disabled)', text: l(:label_notifications_on)
      assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
    end
  end

  def test_dmsf_folder_email_permmissions_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :email_documents
    get '/projects/dmsf/context_menu', params: { id: @folder5.project.id, ids: ["folder-#{@folder5.id}"] }
    assert_response :success
    assert_select 'a.icon-email.disabled', text: l(:field_mail)
  end

  def test_dmsf_folder_email_permmissions_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { id: @folder5.project.id, ids: ["folder-#{@folder5.id}"] }
    assert_response :success
    assert_select 'a:not(icon-email.disabled)', text: l(:field_mail)
  end

  def test_dmsf_folder_watch
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { id: @folder1.project, ids: ["folder-#{@folder1.id}"] }
    assert_response :success
    assert_select 'a.icon-fav-off', text: l(:button_watch)
  end

  def test_dmsf_folder_unwatch
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @folder1.add_watcher @jsmith
    get '/projects/dmsf/context_menu', params: { id: @folder1.project, ids: ["folder-#{@folder1.id}"] }
    assert_response :success
    assert_select 'a.icon-fav', text: l(:button_unwatch)
  end

  def test_dmsf_folder_link
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder_link1.project.id, ids: ["folder-#{@folder_link1.id}"] }
      assert_response :success
      assert_select 'a.icon-edit', text: l(:button_edit)
      assert_select 'a.icon-lock', text: l(:button_lock)
      assert_select 'a.icon-email-add', text: l(:label_notifications_on)
      assert_select 'a.icon-del', text: l(:button_delete)
      assert_select 'a.icon-download', text: l(:button_download)
      assert_select 'a.icon-email', text: l(:field_mail)
    end
  end

  def test_dmsf_folder_link_locked
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @folder_link1.target_folder.lock!
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get '/projects/dmsf/context_menu', params: { id: @folder_link1.project.id, ids: ["folder-#{@folder_link1.id}"] }
      assert_response :success
      assert_select 'a.icon-edit.disabled', text: l(:button_edit)
      assert_select 'a.icon-unlock', text: l(:button_unlock)
      assert_select 'a.icon-lock', text: l(:button_lock), count: 0
      assert_select 'a.icon-email-add.disabled', text: l(:label_notifications_on)
      assert_select 'a.icon-del.disabled', text: l(:button_delete)
    end
  end

  def test_dmsf_multiple
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { id: @project1.id, ids: ["folder-#{@folder1.id}", "file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-edit', text: l(:button_edit), count: 0
    assert_select 'a.icon-unlock', text: l(:button_unlock), count: 0
    assert_select 'a.icon-lock', text: l(:button_lock), count: 0
    assert_select 'a.icon-email-add', text: l(:label_notifications_on), count: 0
    assert_select 'a.icon-email', text: l(:label_notifications_off), count: 0
    assert_select 'a.icon-del', text: l(:button_delete)
    assert_select 'a.icon-download', text: l(:button_download)
    assert_select 'a.icon-email', text: l(:field_mail)
  end

  def test_dmsf_project_watch
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/projects/dmsf/context_menu', params: { ids: ["project-#{@project1.id}"] }
    assert_response :success
    assert_select 'a.icon-fav-off', text: l(:button_watch)
  end

  def test_dmsf_project_unwatch
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @project1.add_watcher @jsmith
    get '/projects/dmsf/context_menu', params: { ids: ["project-#{@project1.id}"] }
    assert_response :success
    assert_select 'a.icon-fav', text: l(:button_unwatch)
  end

  def test_trash_file
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@file1.project.id}/dmsf/trash/context_menu", params: { ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-cancel', text: l(:title_restore)
    assert_select 'a.icon-del', text: l(:button_delete)
  end

  def test_trash_file_manipulation_permissions_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_delete
    @role_manager.remove_permission! :file_manipulation
    get "/projects/#{@file1.project.id}/dmsf/trash/context_menu", params: { ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-cancel.disabled', text: l(:title_restore)
    assert_select 'a.icon-del.disabled', text: l(:button_delete)
  end

  def test_trash_file_manipulation_permissions_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@file1.project.id}/dmsf/trash/context_menu", params: { ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a:not(icon-cancel.disabled)', text: l(:title_restore)
    assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
  end

  def test_trash_file_delete_permissions_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_delete
    get "/projects/#{@file1.project.id}/dmsf/trash/context_menu", params: { ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a.icon-del.disabled', text: l(:button_delete)
  end

  def test_trash_file_delete_permissions_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@file1.project.id}/dmsf/trash/context_menu", params: { ids: ["file-#{@file1.id}"] }
    assert_response :success
    assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
  end

  def test_trash_folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@folder5.project.id}/dmsf/trash/context_menu", params: { ids: ["folder-#{@folder5.id}"] }
    assert_response :success
    assert_select 'a.icon-cancel', text: l(:title_restore)
    assert_select 'a.icon-del', text: l(:button_delete)
  end

  def test_trash_folder_manipulation_permissions_off
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :folder_manipulation
    get "/projects/#{@folder1.project.id}/dmsf/trash/context_menu", params: { ids: ["folder-#{@folder1.id}"] }
    assert_response :success
    assert_select 'a.icon-cancel.disabled', text: l(:title_restore)
    assert_select 'a.icon-del.disabled', text: l(:button_delete)
  end

  def test_trash_folder_manipulation_permissions_on
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@folder1.project.id}/dmsf/trash/context_menu", params: { ids: ["folder-#{@folder1.id}"] }
    assert_response :success
    assert_select 'a:not(icon-cancel.disabled)', text: l(:title_restore)
    assert_select 'a:not(icon-del.disabled)', text: l(:button_delete)
  end

  def test_trash_multiple
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get "/projects/#{@file1.project.id}/dmsf/trash/context_menu",
        params: { ids: ["file-#{@file1.id}", "folder-#{@folder1.id}"] }
    assert_response :success
    assert_select 'a.icon-cancel', text: l(:title_restore)
    assert_select 'a.icon-del', text: l(:button_delete)
  end
end
