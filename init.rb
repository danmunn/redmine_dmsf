# encoding: utf-8
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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
  version '1.5.6'
  url 'http://www.redmine.org/plugins/dmsf'
  author_url 'https://github.com/danmunn/redmine_dmsf/graphs/contributors'
  
  requires_redmine :version_or_higher => '3.0.0'
  
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
        :dmsf_files => [:show, :view],
        :dmsf_files_copy => [:new, :create, :move], 
        :dmsf_workflows => [:log]}, 
      :read => true
    permission :email_documents, {}
    permission :folder_manipulation, 
      {:dmsf => [:new, :create, :delete, :edit, :save, :edit_root, :save_root, :lock, :unlock, :notify_activate, :notify_deactivate, :restore]}
    permission :file_manipulation, 
      {:dmsf_files => [:create_revision, :lock, :unlock, :delete_revision, :notify_activate, :notify_deactivate, :restore], 
        :dmsf_upload => [:upload_files, :upload_file, :upload, :commit_files, :commit],         
        :dmsf_links => [:new, :create, :destroy, :restore]
        }
    permission :file_delete, 
      { :dmsf => [:trash, :delete_entries], 
        :dmsf_files => [:delete]}    
    permission :force_file_unlock, {}
    permission :file_approval,
      {:dmsf_workflows => [:action, :new_action, :autocomplete_for_user, :start, :assign, :assignment]}    
    permission :manage_workflows, 
      {:dmsf_workflows => [:index, :new, :create, :destroy, :show, :new_step, :add_step, :remove_step, :reorder_steps, :update]}
  end   
  
  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :approvalworkflows, {:controller => 'dmsf_workflows', :action => 'index'}, :caption => :label_dmsf_workflow_plural
  end    
  
  Redmine::WikiFormatting::Macros.register do
    desc "Wiki link to DMSF file:\n\n" +
             "{{dmsf(file_id [, title [, revision_id]])}}\n\n" +
         "_file_id_ / _revision_id_ can be found in the link for file/revision download."         
    macro :dmsf do |obj, args|
      raise ArgumentError if args.length < 1 # Requires file id
      file = DmsfFile.visible.find args[0].strip      
      if args[2].blank?
        revision = file.last_revision
      else
        revision = DmsfFileRevision.find(args[2])
        if revision.file != file
          raise ActiveRecord::RecordNotFound
        end
      end      
      if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)        
        file_view_url = url_for(:controller => :dmsf_files, :action => 'view', :id => file, :download => args[2])
        return link_to(h(args[1] ? args[1] : file.title),
          file_view_url,
          :target => '_blank',
          :title => l(:title_title_version_version_download, :title => h(file.title), :version => file.version),
          'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{file_view_url}")
      else        
        raise l(:notice_not_authorized)
      end
    end
  
    desc "Wiki link to DMSF folder:\n\n" +
             "{{dmsff(folder_id [, title])}}\n\n" +
         "_folder_id_ may be missing. _folder_id_ can be found in the link for folder opening."         
    macro :dmsff do |obj, args|
      if args.length < 1
        return link_to l(:link_documents), dmsf_folder_url(@project)
      else        
        folder = DmsfFolder.visible.find args[0].strip
        if User.current && User.current.allowed_to?(:view_dmsf_folders, folder.project)          
          return link_to h(args[1] ? args[1] : folder.title),
            dmsf_folder_url(folder.project, :folder_id => folder)
        else          
          raise l(:notice_not_authorized)
        end
      end      
    end  
    
    desc "Wiki link to DMSF document description:\n\n" +
             "{{dmsfd(file_id)}}\n\n" +
         "_file_id_ can be found in the link for file/revision download." 
    macro :dmsfd do |obj, args|
      raise ArgumentError if args.length < 1 # Requires file id
      file = DmsfFile.visible.find args[0].strip
      if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)        
        return textilizable(file.description)
      else        
        raise l(:notice_not_authorized)
      end   
    end  
    
    desc "Wiki link to DMSF document's content preview:\n\n" +
             "{{dmsft(file_id)}}\n\n" +
         "_file_id_ can be found in the link for file/revision download." 
    macro :dmsft do |obj, args|
      raise ArgumentError if args.length < 2 # Requires file id and lines number
      file = DmsfFile.visible.find args[0].strip
      if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)           
        return file.preview(args[1].strip).gsub("\n", '<br/>').html_safe        
      else        
        raise l(:notice_not_authorized)
      end   
    end  

    desc "Wiki DMSF image:\n\n" +
               "{{dmsf_image(file_id)}}\n" +
               "{{dmsf_image(file_id, size=300)}} -- with custom title and size\n" +
               "{{dmsf_image(file_id, size=640x480)}}"
    macro :dmsf_image do |obj, args|
      args, options = extract_macro_options(args, :size, :title)
      file_id = args.first
      raise 'DMSF document ID required' unless file_id.present?
      size = options[:size]      
      if file = DmsfFile.find_by_id(file_id)
        unless User.current && User.current.allowed_to?(:view_dmsf_files, file.project)        
          raise l(:notice_not_authorized)
        end
        raise 'Not supported image format' unless file.image?
        url = url_for(:controller => :dmsf_files, :action => 'view', :id => file)      
       if size && size.include?('%')
          image_tag(url, :alt => file.title, :width => size, :height => size)
        else
          image_tag(url, :alt => file.title, :size => size)
        end
      else
        raise "Document ID #{file_id} not found"
      end
    end
  end
  
  # Rubyzip configuration
  Zip.unicode_names = true
end

Redmine::Search.map do |search|
  search.register :dmsf_files
  search.register :dmsf_folders
end
