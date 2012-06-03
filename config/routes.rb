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

RedmineApp::Application.routes.draw do
  resources :dmsf

  #/projects/<project>/dmsf/state - dmsf_state controller
  post '/projects/:id/dmsf/state', :controller => 'dmsf_state', :action => 'user_pref_save'


  #/projects/<project>/dmsf/upload - dmsf_upload controller

  post '/projects/:id/dmsf/upload/files', :controller => 'dmsf_upload', :action => 'upload_files'
  post '/projects/:id/dmsf/upload/file', :controller => 'dmsf_upload', :action => 'upload_file'
  post '/projects/:id/dmsf/upload/commit', :controller => 'dmsf_upload', :action => 'commit_files'
  
  #/dmsf/files - dmsf_files controller
  post '/dmsf/files/:id/notify/activate', :controller => 'dmsf_files', :action => 'notify_activate'
  post '/dmsf/files/:id/notify/deactivate', :controller => 'dmsf_files', :action => 'notify_deactivate'
  post '/dmsf/files/:id/lock', :controller => 'dmsf_files', :action => 'lock'
  post '/dmsf/files/:id/unlock', :controller => 'dmsf_files', :action => 'unlock'
  post '/dmsf/files/:id/delete', :controller => 'dmsf_files', :action => 'delete'
  post '/dmsf/files/:id/revision/create', :controller => 'dmsf_files', :action => 'create_revision'
  post '/dmsf/files/:id/revision/delete', :controller => 'dmsf_files', :action => 'delete_revision'

  get '/dmsf/files/:id/download', :controller => 'dmsf_files', :action => 'show'
  get '/dmsf/files/:id', :controller => 'dmsf_files', :action => 'show'


  #
  # files_copy controller
  ##
  post '/dmsf/files/:id/copy/create', :controller => 'dmsf_files_copy', :action => 'create'
  post '/dmsf/files/:id/copy/move', :controller => 'dmsf_files_copy', :action => 'move'
  get '/dmsf/files/:id/copy', :controller => 'dmsf_files_copy', :action => 'new'

end
