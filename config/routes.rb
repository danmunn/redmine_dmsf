# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Pičman <karel.picman@kontron.com>
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

RedmineApp::Application.routes.draw do

  #
  # dmsf controller
  #   /projects/<project>/dmsf
  #   [As this controller also processes 'folders' it maybe better to branch into a folder route rather than leaving it as is]
  ##
  post '/projects/:id/dmsf/create', :controller => 'dmsf', :action => 'create'
  get '/projects/:id/dmsf/notify/activate', :controller => 'dmsf', :action => 'notify_activate', :as => 'notify_activate_dmsf'
  get '/projects/:id/dmsf/notify/deactivate', :controller => 'dmsf', :action => 'notify_deactivate', :as => 'notify_deactivate_dmsf'
  get '/projects/:id/dmsf/delete', :controller => 'dmsf', :action => 'delete', :as => 'delete_dmsf'
  post '/projects/:id/dmsf/save', :controller => 'dmsf', :action => 'save'
  post '/projects/:id/dmsf/save/root', :controller => 'dmsf', :action => 'save_root'
  post '/projects/:id/dmsf/entries', :controller => 'dmsf', :action => 'entries_operation'
  post '/projects/:id/dmsf/tag_changed', :controller => 'dmsf', :action => 'tag_changed', :as => 'tag_changed'
  post '/projects/:id/dmsf/entries/delete', :controller => 'dmsf', :action => 'delete_entries', :as => 'delete_entries'
  post '/projects/:id/dmsf/entries/email', :controller => 'dmsf', :action => 'entries_email'
  get '/projects/:id/dmsf/entries/download_email_entries', :controller => 'dmsf', :action => 'download_email_entries', :as => 'download_email_entries'
  get '/projects/:id/dmsf/lock', :controller => 'dmsf', :action => 'lock', :as => 'lock_dmsf'
  get '/projects/:id/dmsf/unlock', :controller => 'dmsf', :action => 'unlock', :as => 'unlock_dmsf'
  get '/projects/:id/dmsf/', :controller => 'dmsf', :action => 'show', :as => 'dmsf_folder'
  get '/projects/:id/dmsf/new', :controller => 'dmsf', :action => 'new', :as => 'new_dmsf'
  get '/projects/:id/dmsf/edit', :controller=> 'dmsf', :action => 'edit', :as => 'edit_dmsf'
  get '/projects/:id/dmsf/edit/root', :controller=> 'dmsf', :action => 'edit_root', :as => 'edit_root_dmsf'
  get '/projects/:id/dmsf/trash', :controller => 'dmsf', :action => 'trash', :as => 'trash_dmsf'
  get '/projects/:id/dmsf/restore', :controller => 'dmsf', :action => 'restore', :as => 'restore_dmsf'

  #
  # dmsf_state controller
  #   /projects/<project>/dmsf/state
  ##
  post '/projects/:id/dmsf/state', :controller => 'dmsf_state', :action => 'user_pref_save', :as => 'dmsf_user_pref_save'

  #
  #  dmsf_upload controller
  #   /projects/<project>/dmsf/upload - dmsf_upload controller
  ##

  post '/projects/:id/dmsf/upload/files', :controller => 'dmsf_upload', :action => 'upload_files'
  post '/projects/:id/dmsf/upload/file', :controller => 'dmsf_upload', :action => 'upload_file'
  post '/projects/:id/dmsf/upload', :controller => 'dmsf_upload', :action => 'upload'
  post '/projects/:id/dmsf/upload/commit', :controller => 'dmsf_upload', :action => 'commit_files'
  post '/projects/:id/dmsf/commit', :controller => 'dmsf_upload', :action => 'commit'
  
  #
  # dmsf_files controller
  #   /dmsf/files/<file id>
  ##
  get '/dmsf/files/:id/notify/activate', :controller => 'dmsf_files', :action => 'notify_activate', :as => 'notify_activate_dmsf_files'
  get '/dmsf/files/:id/notify/deactivate', :controller => 'dmsf_files', :action => 'notify_deactivate', :as => 'notify_deactivate_dmsf_files'
  get '/dmsf/files/:id/lock', :controller => 'dmsf_files', :action => 'lock', :as => 'lock_dmsf_files'
  get '/dmsf/files/:id/unlock', :controller => 'dmsf_files', :action => 'unlock', :as => 'unlock_dmsf_files'
  post '/dmsf/files/:id/delete', :controller => 'dmsf_files', :action => 'delete', :as => 'delete_dmsf_files'
  post '/dmsf/files/:id/revision/create', :controller => 'dmsf_files', :action => 'create_revision'
  get '/dmsf/files/:id/revision/delete', :controller => 'dmsf_files', :action => 'delete_revision', :as => 'delete_revision'
  get '/dmsf/files/:id/download', :controller => 'dmsf_files', :action => 'show', :download => '' # Otherwise will not route nil download param
  get '/dmsf/files/:id/download/:download', :controller => 'dmsf_files', :action => 'show', :as => 'download_revision'
  get '/dmsf/files/:id/view', :controller => 'dmsf_files', :action => 'view'
  get '/dmsf/files/:id', :controller => 'dmsf_files', :action => 'show', :as => 'dmsf_file'  
  delete '/dmsf/files/:id', :controller => 'dmsf_files', :action => 'delete'
  get '/dmsf/files/:id/restore', :controller => 'dmsf_files', :action => 'restore', :as => 'restore_dmsf_file'

  #
  # url controller
  #   /dmsf/links/<file id>
  ##
  get '/dmsf/links/:id/restore', :controller => 'dmsf_links', :action => 'restore', :as => 'restore_dmsf_link'
  delete '/dmsf/links/:id', :controller => 'dmsf_links', :action => 'delete'

  # Just to keep backward compatibility with old external direct links
  get '/dmsf_files/:id', :controller => 'dmsf_files', :action => 'show'
  get '/dmsf_files/:id/download', :controller => 'dmsf_files', :action => 'show', :download => ''

  #
  # files_copy controller
  #   /dmsf/files/<file id>/copy
  ##
  post '/dmsf/files/:id/copy/create', :controller => 'dmsf_files_copy', :action => 'create'
  post '/dmsf/files/:id/copy/move', :controller => 'dmsf_files_copy', :action => 'move'
  get '/dmsf/files/:id/copy', :controller => 'dmsf_files_copy', :action => 'new', :as => 'copy_file'

  #
  # folders_copy controller
  #   /dmsf/folders/<folder id>/copy
  ##
  #verify :method => :post, :only => [:copy_to], :render => { :nothing => true, :status => :method_not_allowed }
  post '/dmsf/folders/:id/copy/to', :controller => 'dmsf_folders_copy', :action => 'copy_to'
  get '/dmsf/folders/:id/copy', :controller => 'dmsf_folders_copy', :action => 'new', :as => 'copy_folder'

  #
  # DAV4Rack implementation of Webdav [note: if changing path you'll need to update lib/redmine_dmsf/webdav/no_parse.rb also]
  #   /dmsf/webdav
  mount DAV4Rack::Handler.new(
    :root_uri_path => "#{Redmine::Utils::relative_url_root}/dmsf/webdav",
    :resource_class => RedmineDmsf::Webdav::ResourceProxy,
    :controller_class => RedmineDmsf::Webdav::Controller
  ), :at => "/dmsf/webdav"
  
  # Approval workflow    
  resources :dmsf_workflows do
    member do
      get 'autocomplete_for_user'
      get 'action'
      get 'assign'
      get 'log'
      post 'new_action'
      get 'start'
      post 'assignment'
      get 'new_step'
    end
  end
    
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'add_step', :id => /\d+/, :via => :post
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'remove_step', :id => /\d+/, :via => :delete
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'reorder_steps', :id => /\d+/, :via => :put    
  
  # Links
  resources :dmsf_links do
    member do
      get 'restore'
    end    
  end  
  
end
