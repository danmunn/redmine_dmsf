# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

require 'redmine'
require 'zip'
require "#{File.dirname(__FILE__)}/../../lib/redmine_dmsf"

Rails.application.config.after_initialize do
  require 'redmine_dmsf/preview'

  webdav = if Redmine::Plugin.installed?('easy_hosting_services') && EasyHostingServices::EasyMultiTenancy.activated?
             '1'
           else
             '0'
           end
  options = {
    'dmsf_max_file_download' => 0,
    'dmsf_max_email_filesize' => 0,
    'dmsf_storage_directory' => 'files/dmsf',
    'dmsf_index_database' => File.expand_path('dmsf_index', Rails.root),
    'dmsf_stemming_lang' => 'english',
    'dmsf_stemming_strategy' => 'STEM_NONE',
    'dmsf_webdav' => webdav,
    'dmsf_display_notified_recipients' => '0',
    'dmsf_global_title_format' => '',
    'dmsf_columns' => %w[title size modified version workflow author],
    'dmsf_webdav_ignore' => '^(\._|\.DS_Store$|Thumbs.db$)',
    'dmsf_webdav_disable_versioning' => '^\~\$|\.tmp$',
    'dmsf_keep_documents_locked' => '0',
    'dmsf_act_as_attachable' => '0',
    'dmsf_documents_email_from' => '',
    'dmsf_documents_email_reply_to' => '',
    'dmsf_documents_email_links_only' => '0',
    'dmsf_enable_cjk_ngrams' => '0',
    'dmsf_webdav_use_project_names' => '1',
    'dmsf_webdav_ignore_1b_file_for_authentication' => '1',
    'dmsf_projects_as_subfolders' => '0',
    'only_approval_zero_minor_version' => '0',
    'dmsf_max_notification_receivers_info' => 10,
    'office_bin' => 'libreoffice',
    'dmsf_global_menu_disabled' => '0',
    'dmsf_default_query' => '0',
    'empty_minor_version_by_default' => '0',
    'remove_original_documents_module' => '0',
    'dmsf_webdav_authentication' => 'Digest',
    'dmsf_really_delete_files' => '0'
  }

  Setting.define_setting 'plugin_redmine_dmsf', { 'default' => options, 'serialized' => true }
  Redmine::Plugin.find(:redmine_dmsf).settings = { partial: 'settings/dmsf_settings' }

  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :dmsf_approvalworkflows, :dmsf_workflows_path,
              caption: :label_dmsf_workflow_plural,
              icon: 'workflows',
              html: { class: 'icon icon-workflows' },
              if: proc { |_| User.current.admin? }
  end

  # Project menu extension
  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :dmsf, { controller: 'dmsf', action: 'show' },
              caption: :menu_dmsf,
              before: :documents,
              param: :id,
              html: { class: 'icon icon-dmsf' }
  end

  # Main menu extension
  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :dmsf, { controller: 'dmsf', action: 'index' },
              caption: :menu_dmsf,
              html: { class: 'icon-dmsf', category: :rest_extension_modules },
              if: proc {
                User.current.allowed_to?(:view_dmsf_folders, nil, global: true) &&
                  ActiveRecord::Base.connection.data_source_exists?('settings') &&
                  !RedmineDmsf.dmsf_global_menu_disabled?
              }
  end

  Redmine::AccessControl.map do |map|
    map.project_module :dmsf do |pmap|
      pmap.permission :view_dmsf_file_revision_accesses, {}, read: true
      pmap.permission :view_dmsf_file_revisions, {}, read: true
      pmap.permission :view_dmsf_folders, { dmsf: %i[show index] }, read: true
      pmap.permission :user_preferences, { dmsf_state: [:user_pref_save] }, require: :member
      pmap.permission(:view_dmsf_files,
                      { dmsf: %i[entries_operation entries_email download_email_entries add_email append_email
                                 autocomplete_for_user],
                        dmsf_files: %i[show view thumbnail],
                        dmsf_workflows: [:log] },
                      read: true)
      pmap.permission :email_documents,
                      { dmsf_public_urls: [:create] }
      pmap.permission :folder_manipulation,
                      { dmsf: %i[new create delete edit save edit_root save_root lock unlock notify_activate
                                 notify_deactivate restore drop copymove],
                        dmsf_folder_permissions: %i[new append autocomplete_for_user],
                        dmsf_context_menus: [:dmsf] }
      pmap.permission :file_manipulation,
                      { dmsf_files: %i[create_revision lock unlock delete_revision obsolete_revision
                                       notify_activate notify_deactivate restore],
                        dmsf_upload: %i[upload_files upload commit_files commit delete_dmsf_attachment
                                        delete_dmsf_link_attachment multi_upload],
                        dmsf_links: %i[new create destroy restore autocomplete_for_project autocomplete_for_folder],
                        dmsf_context_menus: [:dmsf] }
      pmap.permission :file_delete,
                      { dmsf: %i[trash delete_entries empty_trash],
                        dmsf_files: [:delete],
                        dmsf_trash_context_menus: [:trash] }
      pmap.permission :force_file_unlock, {}
      pmap.permission :file_approval,
                      { dmsf_workflows: %i[action new_action autocomplete_for_user start assign assignment] }
      pmap.permission :manage_workflows,
                      { dmsf_workflows: %i[index new create destroy show new_step add_step remove_step
                                           reorder_steps update update_step delete_step edit] }
      pmap.permission :display_system_folders, {}, read: true
      # Watchers
      pmap.permission :view_dmsf_file_watchers, {}, read: true
      pmap.permission :add_dmsf_file_watchers, { watchers: %i[new create append autocomplete_for_user] }
      pmap.permission :delete_dmsf_file_watchers, { watchers: :destroy }
      pmap.permission :view_dmsf_folder_watchers, {}, read: true
      pmap.permission :add_dmsf_folder_watchers, { watchers: %i[new create append autocomplete_for_user] }
      pmap.permission :delete_dmsf_folder_watchers, { watchers: :destroy }
      pmap.permission :view_project_watchers, {}, read: true
      pmap.permission :add_project_watchers, { watchers: %i[new create append autocomplete_for_user] }
      pmap.permission :delete_project_watchers, { watchers: :destroy }
    end
  end

  # Register panels for My page
  EpmDmsfLockedDocuments.register_to_scope :user, plugin: :redmine_dmsf
  EpmDmsfOpenApprovals.register_to_scope :user, plugin: :redmine_dmsf
  EpmDmsfWatchedDocuments.register_to_scope :user, plugin: :redmine_dmsf

  # DMSF WebDAV digest token
  Token.add_action :dmsf_webdav_digest, max_instances: 1, validity_time: nil
end

Rails.application.configure do
  # Rubyzip configuration
  Zip.unicode_names = true

  Rails.application.config.after_initialize do
    # DMS custom fields
    CustomFieldsHelper::CUSTOM_FIELDS_TABS << { name: 'DmsfFileRevisionCustomField', partial: 'custom_fields/index',
                                                label: :dmsf }
    # Searchable modules
    Redmine::Search.map do |search|
      search.register :dmsf_files
      search.register :dmsf_folders
    end

    # Activities
    Redmine::Activity.register :dmsf_file_revision_accesses, default: false
    Redmine::Activity.register :dmsf_file_revisions
  end

  require "#{File.dirname(__FILE__)}/../../lib/redmine_dmsf/webdav/custom_middleware"
  config.middleware.insert_before ActionDispatch::Cookies, RedmineDmsf::Webdav::CustomMiddleware
end
