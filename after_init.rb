# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

require_dependency 'zip'
require_dependency File.dirname(__FILE__) + '/lib/redmine_dmsf.rb'

ActiveSupport::Dependencies.autoload_paths << File.join(File.dirname(__FILE__), 'app', 'validators')

def dmsf_init
  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :dmsf_approvalworkflows, :dmsf_workflows_path, caption: :label_dmsf_workflow_plural,
              html: { class: 'icon icon-workflows' }, if: Proc.new { |_| User.current.admin? }
  end
  # Project menu extension
  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :dmsf, { controller: 'dmsf', action: 'show' }, caption: :menu_dmsf, before: :documents,
              param: :id
  end
  # Main menu extension
  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :dmsf, { controller: 'dmsf', action: 'index' }, caption: :menu_dmsf,
              html: { class: 'icon-dmsf' },
              if: Proc.new { User.current.allowed_to?(:view_dmsf_folders, nil, global: true) }
  end

  Redmine::AccessControl.map do |map|
    map.project_module :dmsf do |pmap|
      pmap.permission :view_dmsf_file_revision_accesses,
                      read: true
      pmap.permission :view_dmsf_file_revisions,
                      read: true
      pmap.permission :view_dmsf_folders,
                      { dmsf: [:show, :index] },
                      read: true
      pmap.permission :user_preferences,
                      { dmsf_state: [:user_pref_save] }
      pmap.permission :view_dmsf_files,
                      { dmsf: [:entries_operation, :entries_email, :download_email_entries, :tag_changed, :add_email,
                                 :append_email, :autocomplete_for_user],
                       dmsf_files: [:show, :view, :thumbnail],
                       dmsf_workflows: [:log] },
                      read: true
      pmap.permission :email_documents,
                      { dmsf_public_urls: [:create] }
      pmap.permission :folder_manipulation,
                      { dmsf: [:new, :create, :delete, :edit, :save, :edit_root, :save_root, :lock, :unlock,
                                 :notify_activate, :notify_deactivate, :restore, :drop],
                       dmsf_folder_permissions: [:new, :append, :autocomplete_for_user],
                       dmsf_folders_copy: [:new, :copy, :move],
                       dmsf_context_menus: [:dmsf] }
      pmap.permission :file_manipulation,
                      { dmsf_files: [:create_revision, :lock, :unlock, :delete_revision, :obsolete_revision,
                                       :notify_activate, :notify_deactivate, :restore],
                       dmsf_upload: [:upload_files, :upload, :commit_files, :commit, :delete_dmsf_attachment,
                                     :delete_dmsf_link_attachment, :multi_upload],
                       dmsf_links: [:new, :create, :destroy, :restore, :autocomplete_for_project,
                                       :autocomplete_for_folder],
                       dmsf_files_copy: [:new, :copy, :move],
                       dmsf_context_menus: [:dmsf]}
      pmap.permission :file_delete,
                      { dmsf: [:trash, :delete_entries, :empty_trash],
                       dmsf_files: [:delete],
                       dmsf_trash_context_menus: [:trash] }
      pmap.permission :force_file_unlock, {}
      pmap.permission :file_approval,
                      { dmsf_workflows: [:action, :new_action, :autocomplete_for_user, :start, :assign, :assignment] }
      pmap.permission :manage_workflows,
                      { dmsf_workflows: [:index, :new, :create, :destroy, :show, :new_step, :add_step, :remove_step,
                                           :reorder_steps, :update, :update_step, :delete_step, :edit] }
      pmap.permission :display_system_folders,
                      read: true
    end
  end
end

if Redmine::Plugin.installed?(:easy_extensions)
  ActiveSupport.on_load(:easyproject, yield: true) do
    dmsf_init

    require File.expand_path('../app/models/easy_page_modules/easy_dms/epm_dmsf_locked_documents', __FILE__)
    require File.expand_path('../app/models/easy_page_modules/easy_dms/epm_dmsf_open_approvals', __FILE__)

    EpmDmsfLockedDocuments.register_to_scope(:user, plugin: :redmine_dmsf)
    EpmDmsfOpenApprovals.register_to_scope(:user, plugin: :redmine_dmsf)
  end
else
  dmsf_init
end

RedmineExtensions::Reloader.to_prepare do
  # Rubyzip configuration
  Zip.unicode_names = true

  # DMS custom fields
  CustomFieldsHelper::CUSTOM_FIELDS_TABS << { name: 'DmsfFileRevisionCustomField', partial: 'custom_fields/index',
                                              label: :dmsf }

  Redmine::Search.map do |search|
    search.register :dmsf_files
    search.register :dmsf_folders
  end

  Redmine::Activity.register :dmsf_file_revision_accesses, default: false
  Redmine::Activity.register :dmsf_file_revisions

  # Uncomment to remove the original Documents from searching and project's modules (replaced with DMSF)
  # Redmine::Search.available_search_types.delete('documents')
  # Redmine::AccessControl.available_project_modules.delete(:documents)
end

# WebDAV
Rails.configuration.middleware.insert_before ActionDispatch::Cookies, RedmineDmsf::Webdav::CustomMiddleware
