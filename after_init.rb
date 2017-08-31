require_dependency 'zip'
require_dependency File.dirname(__FILE__) + '/lib/redmine_dmsf.rb'

def init
  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :dmsf_approvalworkflows, :dmsf_workflows_path, :caption => :label_dmsf_workflow_plural,
              :html => { :class => 'icon icon-approvalworkflows' }, :if => Proc.new { |_| User.current.admin? }
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :dmsf, { :controller => 'dmsf', :action => 'show' }, :caption => :menu_dmsf, :before => :documents,
              :param => :id
  end

  # Permissions
  Redmine::AccessControl.map do |map|
    map.project_module :dmsf do |pmap|
      pmap.permission :view_dmsf_file_revision_accesses,
                      :read => true
      pmap.permission :view_dmsf_file_revisions,
                      :read => true
      pmap.permission :view_dmsf_folders,
                      {:dmsf => [:show],
                       :dmsf_folders_copy => [:new, :copy_to, :move_to]},
                      :read => true
      pmap.permission :user_preferences,
                      {:dmsf_state => [:user_pref_save]}
      pmap.permission :view_dmsf_files,
                      {:dmsf => [:entries_operation, :entries_email, :download_email_entries, :tag_changed],
                       :dmsf_files => [:show, :view, :thumbnail],
                       :dmsf_files_copy => [:new, :create, :move],
                       :dmsf_workflows => [:log]},
                      :read => true
      pmap.permission :email_documents,
                      {:dmsf_public_urls => [:create]}
      pmap.permission :folder_manipulation,
                      {:dmsf => [:new, :create, :delete, :edit, :save, :edit_root, :save_root, :lock, :unlock,
                                 :notify_activate, :notify_deactivate, :restore],
                       :dmsf_folder_permissions => [:new, :append, :autocomplete_for_user]}
      pmap.permission :file_manipulation,
                      {:dmsf_files => [:create_revision, :lock, :unlock, :delete_revision, :notify_activate,
                                       :notify_deactivate, :restore],
                       :dmsf_upload => [:upload_files, :upload_file, :upload, :commit_files, :commit,
                                        :delete_dmsf_attachment, :delete_dmsf_link_attachment],
                       :dmsf_links => [:new, :create, :destroy, :restore, :autocomplete_for_project,
                                       :autocomplete_for_folder]
                      }
      pmap.permission :file_delete,
                      { :dmsf => [:trash, :delete_entries],
                        :dmsf_files => [:delete]}
      pmap.permission :force_file_unlock, {}
      pmap.permission :file_approval,
                      {:dmsf_workflows => [:action, :new_action, :autocomplete_for_user, :start, :assign, :assignment]}
      pmap.permission :manage_workflows,
                      {:dmsf_workflows => [:index, :new, :create, :destroy, :show, :new_step, :add_step, :remove_step,
                                           :reorder_steps, :update, :update_step, :delete_step, :edit]}
      pmap.permission :display_system_folders,
                      :read => true
    end
  end
end

unless Redmine::Plugin.installed?(:easy_extensions)
  init
else
  ActiveSupport.on_load(:easyproject, yield: true) do
    init
  end
end

ActionDispatch::Reloader.to_prepare do
  # Rubyzip configuration
  Zip.unicode_names = true

  Redmine::Search.map do |search|
    search.register :dmsf_files
    search.register :dmsf_folders
  end

  Redmine::Activity.register :dmsf_file_revision_accesses, :default => false
  Redmine::Activity.register :dmsf_file_revisions
end
