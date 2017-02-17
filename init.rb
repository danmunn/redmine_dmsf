# encoding: utf-8
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

require 'redmine'
require 'redmine_dmsf'
require 'zip'

Redmine::Plugin.register :redmine_dmsf do
  name 'DMSF'
  author 'Vít Jonáš / Daniel Munn / Karel Pičman'
  description 'Document Management System Features'
  version '1.5.9'
  url 'http://www.redmine.org/plugins/dmsf'
  author_url 'https://github.com/danmunn/redmine_dmsf/graphs/contributors'
  
  requires_redmine :version_or_higher => '3.3.0'
  
  settings  :partial => 'settings/dmsf_settings',
            :default => {
              'dmsf_max_file_upload' => '0',
              'dmsf_max_file_download' => '0',
              'dmsf_max_email_filesize' => '0',
              'dmsf_max_ajax_upload_filesize' => '100',
              'dmsf_storage_directory' => Rails.root.join('files/dmsf').to_s,
              'dmsf_index_database' => Rails.root.join('files/dmsf_index').to_s,
              'dmsf_stemming_lang' => 'english',
              'dmsf_stemming_strategy' => 'STEM_NONE',
              'dmsf_webdav' => '1',
              'dmsf_display_notified_recipients' => 0,
              'dmsf_global_title_format' => '',
              'dmsf_columns' => %w(title size modified version workflow author),
              'dmsf_memcached_servers' => '',
              'dmsf_webdav_ignore' => '^(\._|\.DS_Store$|Thumbs.db$)',
              'dmsf_webdav_disable_versioning' => '^\~\$|\.tmp$',
              'dmsf_keep_documents_locked' => false
            }
  
  menu :project_menu, :dmsf, { :controller => 'dmsf', :action => 'show' }, :caption => :menu_dmsf, :before => :documents, :param => :id
    
  Redmine::Activity.register :dmsf_file_revision_accesses, :default => false
  Redmine::Activity.register :dmsf_file_revisions
  
  # Uncomment to remove the original Documents from searching (replaced with DMSF)
  # Redmine::Search.available_search_types.delete('documents')
  
  project_module :dmsf do
    permission :view_dmsf_file_revision_accesses, 
      :read => true
    permission :view_dmsf_file_revisions, 
      :read => true
    permission :view_dmsf_folders, 
      {:dmsf => [:show], 
        :dmsf_folders_copy => [:new, :copy_to, :move_to]}, 
      :read => true
    permission :user_preferences, 
      {:dmsf_state => [:user_pref_save]}
    permission :view_dmsf_files, 
      {:dmsf => [:entries_operation, :entries_email, :download_email_entries, :tag_changed], 
        :dmsf_files => [:show, :view, :thumbnail],
        :dmsf_files_copy => [:new, :create, :move], 
        :dmsf_workflows => [:log]}, 
      :read => true
    permission :email_documents,
       {:dmsf_public_urls => [:create]}
    permission :folder_manipulation, 
      {:dmsf => [:new, :create, :delete, :edit, :save, :edit_root, :save_root, :lock, :unlock, :notify_activate, :notify_deactivate, :restore]}
    permission :file_manipulation, 
      {:dmsf_files => [:create_revision, :lock, :unlock, :delete_revision, :notify_activate, :notify_deactivate, :restore], 
        :dmsf_upload => [:upload_files, :upload_file, :upload, :commit_files, :commit, :delete_dmsf_attachment],
        :dmsf_links => [:new, :create, :destroy, :restore]
        }
    permission :file_delete, 
      { :dmsf => [:trash, :delete_entries], 
        :dmsf_files => [:delete]}    
    permission :force_file_unlock, {}
    permission :file_approval,
      {:dmsf_workflows => [:action, :new_action, :autocomplete_for_user, :start, :assign, :assignment]}    
    permission :manage_workflows, 
      {:dmsf_workflows => [:index, :new, :create, :destroy, :show, :new_step, :add_step, :remove_step, :reorder_steps,
                           :update, :update_step, :delete_step, :edit]}
  end   
  
  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :dmsf_approvalworkflows, 
      {:controller => 'dmsf_workflows', :action => 'index'}, 
      :caption => :label_dmsf_workflow_plural
  end     
  
  # Rubyzip configuration
  Zip.unicode_names = true
end

Redmine::Search.map do |search|
  search.register :dmsf_files
  search.register :dmsf_folders
end
