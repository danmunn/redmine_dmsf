# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
#  Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

if Redmine::Plugin.installed? 'redmine_dmsf'
  RedmineApp::Application.routes.draw do
    #
    # dmsf controller
    #   /projects/<project>/dmsf
    #   [As this controller also processes 'folders' it maybe better to branch into a folder route rather than leaving
    #    it as is]
    ##
    post '/projects/:id/dmsf/create', controller: 'dmsf', action: 'create'
    get '/projects/:id/dmsf/notify/activate', controller: 'dmsf', action: 'notify_activate', as: 'notify_activate_dmsf'
    get '/projects/:id/dmsf/notify/deactivate', controller: 'dmsf',
                                                action: 'notify_deactivate',
                                                as: 'notify_deactivate_dmsf'
    delete '/projects/:id/dmsf/delete', controller: 'dmsf', action: 'delete', as: 'delete_dmsf'
    post '/projects/:id/dmsf/save', controller: 'dmsf', action: 'save'
    post '/projects/:id/dmsf/save/root', controller: 'dmsf', action: 'save_root'
    post '/projects/:id/dmsf/entries', controller: 'dmsf', action: 'entries_operation', as: 'entries_operations_dmsf'
    post '/projects/:id/dmsf/entries/delete', controller: 'dmsf', action: 'delete_entries', as: 'delete_entries'
    post '/projects/:id/dmsf/entries/email', to: 'dmsf#entries_email', as: 'email_entries'
    get '/projects/:id/dmsf/entries/download_email_entries', controller: 'dmsf',
                                                             action: 'download_email_entries',
                                                             as: 'download_email_entries'
    get '/projects/:id/entries/copymove', to: 'dmsf#copymove', as: 'copymove_entries'
    get '/projects/:id/dmsf/lock', controller: 'dmsf', action: 'lock', as: 'lock_dmsf'
    get '/projects/:id/dmsf/unlock', controller: 'dmsf', action: 'unlock', as: 'unlock_dmsf'
    get '/projects/:id/dmsf/', controller: 'dmsf', action: 'show', as: 'dmsf_folder'
    get '/projects/:id/dmsf/new', controller: 'dmsf', action: 'new', as: 'new_dmsf'
    get '/projects/:id/dmsf/edit', controller: 'dmsf', action: 'edit', as: 'edit_dmsf'
    get '/projects/:id/dmsf/edit/root', controller: 'dmsf', action: 'edit_root', as: 'edit_root_dmsf'
    get '/projects/:id/dmsf/trash', controller: 'dmsf', action: 'trash', as: 'trash_dmsf'
    get '/projects/:id/dmsf/restore', controller: 'dmsf', action: 'restore', as: 'restore_dmsf'
    post '/projects/dmsf/expand_folder', controller: 'dmsf', action: 'expand_folder', as: 'expand_folder_dmsf'
    get '/projects/dmsf/add_email', to: 'dmsf#add_email', as: 'add_email_dmsf'
    post '/projects/dmsf/append_email', to: 'dmsf#append_email', as: 'append_email_dmsf'
    get '/projects/dmsf/autocomplete_for_user', to: 'dmsf#autocomplete_for_user'
    put '/projects/:id/dmsf', controller: 'dmsf', action: 'drop'
    get '/projects/:id/dmsf/empty_trash', to: 'dmsf#empty_trash', as: 'empty_trash'
    get '/dmsf', to: 'dmsf#index', as: 'dmsf_index'
    get '/dmsf/digest', to: 'dmsf#digest', as: 'dmsf_digest'
    post '/dmsf/digest', to: 'dmsf#reset_digest', as: 'dmsf_reset_digest'

    # dmsf_context_menu_controller
    match '/projects/dmsf/context_menu', to: 'dmsf_context_menus#dmsf', as: 'dmsf_context_menu', via: %i[get post]
    match '/projects/:id/dmsf/trash/context_menu', to: 'dmsf_context_menus#trash',
                                                   as: 'dmsf_trash_context_menu',
                                                   via: %i[get post]

    #
    # dmsf_state controller
    #   /projects/<project>/dmsf/state
    ##
    post '/projects/:id/dmsf/state', controller: 'dmsf_state', action: 'user_pref_save', as: 'dmsf_user_pref_save'

    #
    #  dmsf_upload controller
    #   /projects/<project>/dmsf/upload - dmsf_upload controller
    ##

    get '/projects/:id/dmsf/upload/multi_upload', controller: 'dmsf_upload',
                                                  action: 'multi_upload',
                                                  as: 'multi_dmsf_upload'
    post '/projects/:id/dmsf/upload/files', controller: 'dmsf_upload', action: 'upload_files'
    get '/projects/:id/dmsf/upload/files', controller: 'dmsf_upload', action: 'upload_files'
    post '/projects/:id/dmsf/upload', controller: 'dmsf_upload', action: 'upload'
    post '/projects/:id/dmsf/upload/commit', controller: 'dmsf_upload', action: 'commit_files'
    post '/projects/:id/dmsf/commit', controller: 'dmsf_upload', action: 'commit'
    post 'dmsf_uploads', to: 'dmsf_upload#upload'
    delete '/dmsf/attachments/:id/delete', to: 'dmsf_upload#delete_dmsf_attachment', as: 'dmsf_attachment'
    delete '/dmsf/link_attachments/:id/delete', to: 'dmsf_upload#delete_dmsf_link_attachment',
                                                as: 'dmsf_link_attachment'

    #
    # dmsf_links controller
    #   /dmsf/links/<file id>
    ##
    get '/dmsf/links/:id/restore', controller: 'dmsf_links', action: 'restore', as: 'restore_dmsf_link'
    delete '/dmsf/links/:id', controller: 'dmsf_links', action: 'delete'

    # Just to keep backward compatibility with old external direct links
    get '/dmsf_files/:id', controller: 'dmsf_files', action: 'show'
    get '/dmsf_files/:id/download', controller: 'dmsf_files', action: 'show', download: ''

    #
    # dmsf_files controller
    #   /dmsf/files/<file id>
    ##
    get '/dmsf/files/:id/notify/activate', controller: 'dmsf_files',
                                           action: 'notify_activate',
                                           as: 'notify_activate_dmsf_files'
    get '/dmsf/files/:id/notify/deactivate', controller: 'dmsf_files',
                                             action: 'notify_deactivate',
                                             as: 'notify_deactivate_dmsf_files'
    get '/dmsf/files/:id/lock', controller: 'dmsf_files', action: 'lock', as: 'lock_dmsf_files'
    get '/dmsf/files/:id/unlock', controller: 'dmsf_files', action: 'unlock', as: 'unlock_dmsf_files'
    post '/dmsf/files/:id/delete', controller: 'dmsf_files', action: 'delete', as: 'delete_dmsf_files'
    post '/dmsf/files/:id/revision/create', controller: 'dmsf_files', action: 'create_revision'
    get '/dmsf/files/:id/revision/delete', controller: 'dmsf_files', action: 'delete_revision', as: 'delete_revision'
    get '/dmsf/files/:id/revision/obsolete', controller: 'dmsf_files',
                                             action: 'obsolete_revision',
                                             as: 'obsolete_revision'
    get '/dmsf/files/:id/download', to: 'dmsf_files#view',
                                    download: '',
                                    as: 'download_dmsf_file' # Otherwise will not route nil into the download param
    get '/dmsf/files/:id/view', to: 'dmsf_files#view', as: 'view_dmsf_file'
    get '/dmsf/files/:id', controller: 'dmsf_files', action: 'show', as: 'dmsf_file'
    delete '/dmsf/files/:id', controller: 'dmsf_files', action: 'delete'
    get '/dmsf/files/:id/restore', controller: 'dmsf_files', action: 'restore', as: 'restore_dmsf_file'
    get '/dmsf/files/:id/thumbnail', to: 'dmsf_files#thumbnail', as: 'dmsf_thumbnail'
    get '/dmsf/files/:id/:filename', to: 'dmsf_files#view', id: /\d+/, filename: /.*/, as: 'static_dmsf_file'

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
        put 'update_step'
        delete 'delete_step'
      end
    end

    post 'dmsf_workflows/:id/edit', controller: 'dmsf_workflows', action: 'add_step', id: /\d+/, via: :post
    delete 'dmsf_workflows/:id/edit', controller: 'dmsf_workflows', action: 'remove_step', id: /\d+/, via: :delete
    put 'dmsf_workflows/:id/edit', controller: 'dmsf_workflows', action: 'reorder_steps', id: /\d+/, via: :put

    # Links
    resources :dmsf_links do
      member do
        get 'restore'
        get 'autocomplete_for_project'
        get 'autocomplete_for_folder'
      end
    end

    # Public URLs
    resource :dmsf_public_urls

    # Folder permissions
    resource :dmsf_folder_permissions do
      member do
        get 'autocomplete_for_user'
        post 'append'
      end
    end

    # WebDAV workaround for clients checking WebDAV availability in the root
    unless Redmine::Plugin.installed?('easy_extensions')
      match '/',
            to: ->(env) { [405, {}, ["#{env['REQUEST_METHOD']} method is not allowed"]] },
            via: %i[propfind options]
    end
    match '/dmsf',
          to: ->(env) { [405, {}, ["#{env['REQUEST_METHOD']} method is not allowed"]] },
          via: %i[propfind options]
  end
end
