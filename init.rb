# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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
  author 'Vit Jonas / Daniel Munn / Karel Picman'
  description 'Document Management System Features'
  version '1.4.8 stable'
  url 'http://www.redmine.org/plugins/dmsf'
  author_url 'https://github.com/danmunn/redmine_dmsf/graphs/contributors'
  
  requires_redmine :version_or_higher => '2.3.0'
  
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
      'dmsf_display_notified_recipients' => 0
    }
  
  menu :project_menu, :dmsf, { :controller => 'dmsf', :action => 'show' }, :caption => :menu_dmsf, :before => :documents, :param => :id
  
  activity_provider :dmsf_files, :class_name => 'DmsfFileRevision', :default => true
  
  project_module :dmsf do
    permission :view_dmsf_folders, 
      {:dmsf => [:show], 
        :dmsf_folders_copy => [:new, :copy_to, :move_to]}, 
      :read => true
    permission :user_preferences, 
      {:dmsf_state => [:user_pref_save]}
    permission :view_dmsf_files, 
      {:dmsf => [:entries_operation, :entries_email, :download_email_entries, :tag_changed], 
        :dmsf_files => [:show], 
        :dmsf_files_copy => [:new, :create, :move], 
        :dmsf_workflows => [:log]}, 
      :read => true
    permission :folder_manipulation, 
      {:dmsf => [:new, :create, :delete, :edit, :save, :edit_root, :save_root, :lock, :unlock, :notify_activate, :notify_deactivate, :delete_entries]}
    permission :file_manipulation, 
      {:dmsf_files => [:create_revision, :delete, :lock, :unlock, :delete_revision, :notify_activate, :notify_deactivate], 
        :dmsf_upload => [:upload_files, :upload_file, :commit_files], 
        :dmsf_workflows => [:action, :new_action, :autocomplete_for_user, :start, :assign, :assignment],
        :dmsf_links => [:new, :create, :destroy]
        }
    permission :manage_workflows, 
      {:dmsf_workflows => [:index, :new, :create, :destroy, :show, :add_step, :remove_step, :reorder_steps, :update]}
    permission :force_file_unlock, {}
  end   
  
  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :approvalworkflows, {:controller => 'dmsf_workflows', :action => 'index'}, :caption => :label_dmsf_workflow_plural        
  end    
  
  Redmine::WikiFormatting::Macros.register do
    desc "Wiki link to DMSF file:\n\n" +
             "!{{dmsf(file_id [, title [, revision_id]])}}\n\n" +
         "_file_id_ / _revision_id_ can be found in link for file/revision download."
         
    macro :dmsf do |obj, args|
      return nil if args.length < 1 # require file id
      entry_id = args[0].strip
      entry = DmsfFile.find(entry_id)
      unless entry.nil? || entry.deleted
        title = args[1] ? args[1] : entry.title
        revision = args[2] ? args[2] : ''
        return link_to "#{title}", :controller => 'dmsf_files', :action => 'show', :id => entry, :download => revision, :only_path => false
      end
      nil
    end
  end
  
  Redmine::WikiFormatting::Macros.register do
    desc "Wiki link to DMSF folder:\n\n" +
             "!{{dmsff(folder_id [, title])}}\n\n" +
         "_folder_id_ may be missing. _folder_id_ can be found in link for folder opening."
         
    macro :dmsff do |obj, args|
      if args.length < 1
        return link_to l(:link_documents), :controller => 'dmsf', :action => 'show', :id => @project, :only_path => false
      else
        entry_id = args[0].strip
        entry = DmsfFolder.find(entry_id)
        unless entry.nil?
          title = args[1] ? args[1] : entry.title
          return link_to "#{title}", :controller => 'dmsf', :action => 'show', :id => entry.project, :folder_id => entry, :only_path => false
        end
      end
      nil
    end
  end
  
  Redmine::WikiFormatting::Macros.register do
    desc "Wiki link to DMSF document description:\n\n" +
             "{{dmsfd(file_id [, title])}}\n\n" +
         "_file_id_ / _revision_id_ can be found in link for file/revision download." 

    macro :dmsfd do |obj, args|
      return nil if args.length < 1 # require file id
      entry_id = args[0].strip
      entry = DmsfFile.find(entry_id)
      unless entry.nil? || entry.deleted
        title = args[1] ? args[1] : entry.title
        return link_to "#{title}", :controller => 'dmsf_files', :action => 'show', :id => entry, :only_path => false
      end
      nil
    end
  end    
  
  # Rubyzip configuration
  Zip.unicode_names = true
end

Redmine::Search.map do |search|
  search.register :dmsf_files
  search.register :dmsf_folders
end
