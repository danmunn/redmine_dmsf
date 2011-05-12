# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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

Redmine::Plugin.register :redmine_dmsf do
  name "DMSF"
  author "Vít Jonáš"
  description "Document Management System Features for Redmine"
  version "0.6.0"
  url "https://code.google.com/p/redmine-dmsf/"
  author_url "mailto:vit.jonas@kontron-czech.com"
  
  requires_redmine :version_or_higher => '1.1.0'
  
  settings  :partial => 'settings/dmsf_settings',
            :default => {
              "dmsf_max_file_upload" => "0",
              "dmsf_max_file_download" => "0",
              "dmsf_storage_directory" => "#{RAILS_ROOT}/files/dmsf",
              "dmsf_index_database" => "#{RAILS_ROOT}/files/dmsf_index",
              "dmsf_stemming_lang" => "english",
              "dmsf_stemming_strategy" => "STEM_NONE"
            }
  
  menu :project_menu, :dmsf, { :controller => 'dmsf', :action => 'index' }, :caption => 'DMSF', :after => :activity, :param => :id
  #delete_menu_item :project_menu, :documents
  
  activity_provider :dmsf_files, :class_name => "DmsfFileRevision", :default => true
  
  project_module :dmsf do
    permission :browse_documents, {:dmsf => [:index]}
    permission :user_preferences, {:dmsf_state => [:user_pref, :user_pref_save]}
    permission :view_dmsf_files, {:dmsf => [:download_file, :download_revision, :entries_operation, :email_entries_send],
      :dmsf_detail => [:file_detail]}
    permission :folder_manipulation, {:dmsf_detail => [:create_folder, :delete_folder, :folder_detail, :save_folder]}
    permission :file_manipulation, {:dmsf_detail => [:upload_files, :upload_file, :commit_files, :save_file, :delete_file],
      :dmsf_state => [:lock_file, :unlock_file]}
    permission :file_approval, {:dmsf_detail => [:approve_file, :delete_revision], 
      :dmsf_state => [:file_notify_activate, :file_notify_deactivate, :folder_notify_activate, :folder_notify_deactivate]}
    permission :force_file_unlock, {:dmsf_state => [:force_file_unlock]}
  end
  
  Redmine::WikiFormatting::Macros.register do
    desc "Wiki link to DMSF content:\n\n" +
             "  File: !{{dmsf(file_id)}}\n\n" +
         "_file_id_ can be found in link for file download"
         
    macro :dmsf do |obj, args|
      return nil if args.length < 1 # require file id
      return nil if @project == nil
      entry_id = args[0].strip
      file = DmsfFile.find(entry_id)
      unless file.nil? || file.deleted
        return nil if file.project != @project
        return link_to "#{file.last_revision.title}", :controller => "dmsf", :action => "download_file", :id => @project, :file_id => file
      end
      nil
    end
  end
  
end

Redmine::Search.map do |search|
  search.register :dmsf_files
end
