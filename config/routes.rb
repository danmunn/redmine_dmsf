# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012 Daniel Munn <dan.munn@munnster.co.uk>
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
  post '/projects/:id/dmsf/notify/activate', :controller => 'dmsf', :action => 'notify_activate'
  post '/projects/:id/dmsf/notify/deactivate', :controller => 'dmsf', :action => 'notify_deactivate'
  post '/projects/:id/dmsf/delete', :controller => 'dmsf', :action => 'delete'
  post '/projects/:id/dmsf/save', :controller => 'dmsf', :action => 'save'
  post '/projects/:id/dmsf/save/root', :controller => 'dmsf', :action => 'save_root'
  post '/projects/:id/dmsf/entries', :controller => 'dmsf', :action => 'entries_operation'
  post '/projects/:id/dmsf/entries/delete', :controller => 'dmsf', :action => 'delete_entries'
  post '/projects/:id/dmsf/entries/email', :controller => 'dmsf', :action => 'entries_email'
  post '/projects/:id/dmsf/lock', :controller => 'dmsf', :action => 'lock'
  post '/projects/:id/dmsf/unlock', :controller => 'dmsf', :action => 'unlock'
  get '/projects/:id/dmsf/', :controller => 'dmsf', :action => 'show'
  get '/projects/:id/dmsf/new', :controller => 'dmsf', :action => 'new'
  get '/projects/:id/dmsf/edit', :controller=> 'dmsf', :action => 'edit'
  get '/projects/:id/dmsf/edit/root', :controller=> 'dmsf', :action => 'edit_root'

  #
  # dmsf_state controller
  #   /projects/<project>/dmsf/state
  ##
  post '/projects/:id/dmsf/state', :controller => 'dmsf_state', :action => 'user_pref_save'


  #
  #  dmsf_upload controller
  #   /projects/<project>/dmsf/upload - dmsf_upload controller
  ##

  post '/projects/:id/dmsf/upload/files', :controller => 'dmsf_upload', :action => 'upload_files'
  post '/projects/:id/dmsf/upload/file', :controller => 'dmsf_upload', :action => 'upload_file'
  post '/projects/:id/dmsf/upload/commit', :controller => 'dmsf_upload', :action => 'commit_files'
  
  #
  # dmsf_files controller
  #   /dmsf/files/<file id>
  ##
  post '/dmsf/files/:id/notify/activate', :controller => 'dmsf_files', :action => 'notify_activate'
  post '/dmsf/files/:id/notify/deactivate', :controller => 'dmsf_files', :action => 'notify_deactivate'
  post '/dmsf/files/:id/lock', :controller => 'dmsf_files', :action => 'lock'
  post '/dmsf/files/:id/unlock', :controller => 'dmsf_files', :action => 'unlock'
  post '/dmsf/files/:id/delete', :controller => 'dmsf_files', :action => 'delete'
  post '/dmsf/files/:id/revision/create', :controller => 'dmsf_files', :action => 'create_revision'
  post '/dmsf/files/:id/revision/delete', :controller => 'dmsf_files', :action => 'delete_revision'
  get '/dmsf/files/:id/download', :controller => 'dmsf_files', :action => 'show', :download => '' #Otherwise will not route nil download param
  get '/dmsf/files/:id/download/:download', :controller => 'dmsf_files', :action => 'show'
  get '/dmsf/files/:id', :controller => 'dmsf_files', :action => 'show'
  # Just to keep backward compatibility of external url links
  get '/dmsf_files/:id', :controller => 'dmsf_files', :action => 'show'

  # Just to keep backward compatibility with old external direct links
  get '/dmsf_files/:id', :controller => 'dmsf_files', :action => 'show'

  #
  # files_copy controller
  #   /dmsf/files/<file id>/copy
  ##
  post '/dmsf/files/:id/copy/create', :controller => 'dmsf_files_copy', :action => 'create'
  post '/dmsf/files/:id/copy/move', :controller => 'dmsf_files_copy', :action => 'move'
  get '/dmsf/files/:id/copy', :controller => 'dmsf_files_copy', :action => 'new'

  #
  # folders_copy controller
  #   /dmsf/folders/<folder id>/copy
  ##
  #verify :method => :post, :only => [:copy_to], :render => { :nothing => true, :status => :method_not_allowed }
  post '/dmsf/folders/:id/copy/to', :controller => 'dmsf_folders_copy', :action => 'copy_to'
  get '/dmsf/folders/:id/copy', :controller => 'dmsf_folders_copy', :action => 'new'

  #
  # DAV4Rack implementation of Webdav [note: if changing path you'll need to update lib/redmine_dmsf/webdav/no_parse.rb also]
  #   /dmsf/webdav
  mount DAV4Rack::Handler.new(
    :root_uri_path => "/dmsf/webdav",
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
      post 'start'
      post 'assignment'
    end
  end
  
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'add_step', :id => /\d+/, :via => :post
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'remove_step', :id => /\d+/, :via => :delete
  match 'dmsf_workflows/:id/edit', :controller => 'dmsf_workflows', :action => 'reorder_steps', :id => /\d+/, :via => :put    
end
