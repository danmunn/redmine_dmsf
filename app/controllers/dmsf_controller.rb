# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

class DmsfController < ApplicationController
  include RedmineDmsf::DmsfZip

  before_action :find_project
  before_action :authorize, :except => [:expand_folder]
  before_action :find_folder, :except => [:new, :create, :edit_root, :save_root, :add_email, :append_email,
                                          :autocomplete_for_user]
  before_action :find_parent, :only => [:new, :create]
  before_action :tree_view, :only => [:delete, :show]
  before_action :permissions

  accept_api_auth :show, :create, :save, :delete

  helper :all
  helper :dmsf_folder_permissions

  def permissions
    render_403 unless DmsfFolder.permissions?(@folder, false)
    true
  end

  def expand_folder
    @tree_view = true
    get_display_params
    @idnt = params[:idnt].present? ? params[:idnt].to_i + 1 : 0
    @pos = params[:pos].present? ? params[:pos].to_f : 0.0
    respond_to do |format|
      format.js { render :action => 'dmsf_rows' }
    end
  end

  def show
    # also try to lookup folder by title if this is API call
    find_folder_by_title if [:xml, :json].include? request.format.to_sym
    get_display_params
    if (@folder && @folder.deleted?) || (params[:folder_title].present? && !@folder)
      render_404
      return
    end
    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
      format.csv  {
        filename = @project.name
        filename << "_#{@folder.title}" if @folder
        filename << DateTime.current.strftime('_%Y%m%d%H%M%S.csv')
        send_data(DmsfHelper.dmsf_to_csv(@folder ? @folder : @project, params[:settings][:dmsf_columns]),
                  :type => 'text/csv; header=present', :filename => filename)
      }
    end
  end

  def trash
    @folder_manipulation_allowed = User.current.allowed_to? :folder_manipulation, @project
    @file_manipulation_allowed = User.current.allowed_to? :file_manipulation, @project
    @file_delete_allowed = User.current.allowed_to? :file_delete, @project
    @subfolders = DmsfFolder.deleted.where(project_id: @project.id)
    @files = DmsfFile.deleted.where(project_id: @project.id)
    @dir_links = DmsfLink.deleted.where(project_id: @project.id, target_type: DmsfFolder.model_name.to_s)
    @file_links = DmsfLink.deleted.where(project_id: @project.id, target_type: DmsfFile.model_name.to_s)
    @url_links = DmsfLink.deleted.where(project_id: @project.id, target_type: 'DmsfUrl')
  end

  def download_email_entries
    # IE has got a tendency to cache files
    expires_in(0.year, "must-revalidate" => true)
    send_file(
        params[:path],
        :filename => 'Documents.zip',
        :type => 'application/zip',
        :disposition => 'attachment')
    rescue Exception => e
      flash[:errors] = e.message
  end

  def entries_operation
    # Download/Email
    if params[:ids].present?
      selected_folders = params[:ids].select{ |x| x =~ /folder-\d+/ }.map{ |x| $1.to_i if x =~ /folder-(\d+)/ }
      selected_files = params[:ids].select{ |x| x =~ /file-\d+/ }.map{ |x| $1.to_i if x =~ /file-(\d+)/ }
      selected_dir_links = params[:ids].select{ |x| x =~ /folder-link-\d+/ }.map{ |x| $1.to_i if x =~ /folder-link-(\d+)/ }
      selected_file_links = params[:ids].select{ |x| x =~ /file-link-\d+/ }.map{ |x| $1.to_i if x =~ /file-link-(\d+)/ }
      selected_url_links = params[:ids].select{ |x| x =~ /url-link-\d+/ }.map{ |x| $1.to_i if x =~ /url-link-(\d+)/ }
    else
      selected_folders = []
      selected_files = []
      selected_dir_links = []
      selected_file_links = []
      selected_url_links = []
    end

    if selected_folders.blank? && selected_files.blank? &&
      selected_dir_links.blank? && selected_file_links.blank? &&
      selected_url_links.blank?
      flash[:warning] = l(:warning_no_entries_selected)
      redirect_to :back
      return
    end

    if selected_dir_links.present? &&
      (params[:email_entries].present? || params[:download_entries].present?)
        selected_folders = DmsfLink.where(id: selected_dir_links).pluck(:target_id) | selected_folders
    end

    if selected_file_links.present? &&
      (params[:email_entries].present? || params[:download_entries].present?)
        selected_files = DmsfLink.where(id: selected_file_links).pluck(:target_id) | selected_files
    end

    begin
      if params[:email_entries].present?
        email_entries(selected_folders, selected_files)
      elsif params[:restore_entries].present?
        restore_entries(selected_folders, selected_files, selected_dir_links, selected_file_links, selected_url_links)
        redirect_to :back
      elsif params[:delete_entries].present?
        delete_entries(selected_folders, selected_files, selected_dir_links, selected_file_links, selected_url_links, false)
        redirect_to :back
      elsif params[:destroy_entries].present?
        delete_entries(selected_folders, selected_files, selected_dir_links, selected_file_links, selected_url_links, true)
        redirect_to :back
      else
        download_entries(selected_folders, selected_files)
      end
    rescue FileNotFound
      render_404
    rescue DmsfAccessError
      render_403
    rescue StandardError => e
      flash[:errors] = e.message
      Rails.logger.error e.message
    end
  end

  def tag_changed
    # Tag filter
    if params[:dmsf_folder]
      params[:dmsf_folder][:custom_field_values].each do |key, value|
        return redirect_to dmsf_folder_path id: @project, folder_id: @folder, custom_field_id: key, custom_value: value
      end
    end
    redirect_to :back
  end

  def entries_email
    if params[:email][:to].strip.blank?
      flash[:errors] = l(:error_email_to_must_be_entered)
    else
      DmsfMailer.deliver_send_documents(@project, params[:email].permit!, User.current)
      File.delete(params[:email][:zipped_content])
      flash[:notice] = l(:notice_email_sent, params[:email][:to])
    end
    redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder)
  end

  def new
    @folder = DmsfFolder.new
    @pathfolder = @parent
    render :action => 'edit'
  end

  def edit
    @parent = @folder.dmsf_folder
    @pathfolder = copy_folder(@folder)
    @force_file_unlock_allowed = User.current.allowed_to?(:force_file_unlock, @project)
  end

  def create
    @folder = DmsfFolder.new
    @folder.project = @project
    @folder.user = User.current
    saved = @folder.update_from_params(params)
    respond_to do |format|
      format.js
      format.api  {
        unless saved
          render_validation_errors(@folder)
        end
      }
      format.html {
        if saved
          flash[:notice] = l(:notice_folder_created)
          redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder.dmsf_folder)
        else
          @pathfolder = @parent
          render :action => 'edit'
        end
      }
    end

  end

  def save
    unless params[:dmsf_folder]
      redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder)
      return
    end
    @pathfolder = copy_folder(@folder)
    saved = @folder.update_from_params(params)
    respond_to do |format|
      format.api  {
        unless saved
          render_validation_errors(@folder)
        end
      }
      format.html {
        if saved
          flash[:notice] = l(:notice_folder_details_were_saved)
          redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder.dmsf_folder)
        else
          render :action => 'edit'
        end
      }
    end
  end

  def delete
    commit = params[:commit] == 'yes'
    result = @folder.delete(commit)
    if result
      flash[:notice] = l(:notice_folder_deleted)
    else
      flash[:errors] = @folder.errors.full_messages.to_sentence
    end
    respond_to do |format|
      format.html do
        if commit || @tree_view
          redirect_to :back
        else
          redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder.dmsf_folder)
        end
      end
      format.api { result ? render_api_ok : render_validation_errors(@folder) }
    end
  end

  def restore
    if @folder.restore
      flash[:notice] = l(:notice_dmsf_folder_restored)
    else
      flash[:errors] = @folder.errors.full_messages.to_sentence
    end
    redirect_to :back
  end

  def edit_root
  end

  def save_root
    if params[:project]
      @project.dmsf_description = params[:project][:dmsf_description]
      if @project.save
        flash[:notice] = l(:notice_folder_details_were_saved)
      else
        flash[:errors] = @project.errors.full_messages.to_sentence
      end
    end
    redirect_to dmsf_folder_path(:id => @project)
  end

  def notify_activate
    if (@folder && @folder.notification) || (@folder.nil? && @project.dmsf_notification)
      flash[:warning] = l(:warning_folder_notifications_already_activated)
    else
      if @folder
        @folder.notify_activate
      else
        @project.dmsf_notification = true
        @project.save!
      end
      flash[:notice] = l(:notice_folder_notifications_activated)
    end
    redirect_to :back
  end

  def notify_deactivate
    if (@folder && !@folder.notification) || (@folder.nil? && !@project.dmsf_notification)
      flash[:warning] = l(:warning_folder_notifications_already_deactivated)
    else
      if @folder
        @folder.notify_deactivate
      else
        @project.dmsf_notification = nil
        @project.save!
      end
      flash[:notice] = l(:notice_folder_notifications_deactivated)
    end
    redirect_to :back
  end

  def lock
    if @folder.nil?
      flash[:warning] = l(:warning_foler_unlockable)
    elsif @folder.locked?
      flash[:warning] = l(:warning_folder_already_locked)
    else
      @folder.lock!
      flash[:notice] = l(:notice_folder_locked)
    end
      redirect_to :back
  end

  def unlock
    if @folder.nil?
      flash[:warning] = l(:warning_foler_unlockable)
    elsif !@folder.locked?
      flash[:warning] = l(:warning_folder_not_locked)
    else
      if @folder.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @project)
        @folder.unlock!
        flash[:notice] = l(:notice_folder_unlocked)
      else
        flash[:errors] = l(:error_only_user_that_locked_folder_can_unlock_it)
      end
    end
     redirect_to :back
  end

  def add_email
    @principals = users_for_new_users
  end

  def append_email
    @principals = Principal.where(id: params[:user_ids]).to_a
    head :success if @principals.blank?
  end

  def autocomplete_for_user
    @principals = users_for_new_users
    respond_to do |format|
      format.js
    end
  end

  private

  def users_for_new_users
    Principal.active.visible.member_of(@project).like(params[:q]).order(:type, :lastname).to_a
  end

  def email_entries(selected_folders, selected_files)
    zip = Zip.new
    zip_entries(zip, selected_folders, selected_files)

    zipped_content = DmsfHelper.temp_dir.join(DmsfHelper.temp_filename('dmsf_email_sent_documents.zip'))

    File.open(zipped_content, 'wb') do |f|
      File.open(zip.finish, 'rb') do |zip_file|
        while (buffer = zip_file.read(8192))
          f.write(buffer)
        end
      end
    end

    max_filesize = Setting.plugin_redmine_dmsf['dmsf_max_email_filesize'].to_f
    if max_filesize > 0 && File.size(zipped_content) > max_filesize * 1048576
      raise EmailMaxFileSize
    end

    zip.files.each do |f|
      audit = DmsfFileRevisionAccess.new
      audit.user = User.current
      audit.dmsf_file_revision = f.last_revision
      audit.action = DmsfFileRevisionAccess::EmailAction
      audit.save!
    end

    @email_params = {
      :zipped_content => zipped_content,
      :folders => selected_folders,
      :files => selected_files,
      :subject => "#{@project.name} #{l(:label_dmsf_file_plural).downcase}",
      :from => Setting.plugin_redmine_dmsf['dmsf_documents_email_from'].presence ||
        "#{User.current.name} <#{User.current.mail}>",
      :reply_to => Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to']
    }
    render :action => 'email_entries'
  rescue Exception
    raise
  ensure
    zip.close if zip
  end

  def download_entries(selected_folders, selected_files)
    zip = Zip.new
    zip_entries(zip, selected_folders, selected_files)
    zip.files.each do |f|
      audit = DmsfFileRevisionAccess.new
      audit.user = User.current
      audit.dmsf_file_revision = f.last_revision
      audit.action = DmsfFileRevisionAccess::DownloadAction
      audit.save!
    end
    send_file(zip.finish,
      :filename => filename_for_content_disposition("#{@project.name}-#{DateTime.current.strftime('%y%m%d%H%M%S')}.zip"),
      :type => 'application/zip',
      :disposition => 'attachment')
  rescue StandardError
    raise
  ensure
    zip.close if zip
  end

  def zip_entries(zip, selected_folders, selected_files)
    member = Member.find_by(user_id: User.current.id, project_id: @project.id)
    selected_folders.each do |selected_folder_id|
      folder = DmsfFolder.visible.find_by(id: selected_folder_id)
      if folder
        zip.add_folder(folder, member, (folder.dmsf_folder.dmsf_path_str if folder.dmsf_folder))
      else
        raise FileNotFound
      end
    end
    selected_files.each do |selected_file_id|
      file = DmsfFile.visible.find_by(id: selected_file_id)
      unless file && file.last_revision && File.exist?(file.last_revision.disk_file)
        raise FileNotFound
      end
      unless (file.project == @project) || User.current.allowed_to?(:view_dmsf_files, file.project)
        raise DmsfAccessError
      end
      zip.add_file(file, member, (file.dmsf_folder.dmsf_path_str if file.dmsf_folder))
    end
    max_files = Setting.plugin_redmine_dmsf['dmsf_max_file_download'].to_i
    if max_files > 0 && zip.files.length > max_files
      raise ZipMaxFilesError
    end
    zip
  end

  def restore_entries(selected_folders, selected_files, selected_dir_links, selected_file_links, selected_url_links)
    # Folders
    selected_folders.each do |id|
      folder = DmsfFolder.find_by(id: id)
      if folder
        unless folder.restore
          flash[:errors] = folder.errors.full_messages.to_sentence
        end
      else
        raise FileNotFound
      end
    end
    # Files
    selected_files.each do |id|
      file = DmsfFile.find_by(id: id)
      if file
        unless file.restore
          flash[:errors] = file.errors.full_messages.to_sentence
        end
      else
        raise FileNotFound
      end
    end
    # Links
    (selected_dir_links + selected_file_links + selected_url_links).each do |id|
      link = DmsfLink.find_by(id: id)
      if link
        unless link.restore
          flash[:errors] = link.errors.full_messages.to_sentence
        end
      else
        raise FileNotFound
      end
    end
  end

  def delete_entries(selected_folders, selected_files, selected_dir_links, selected_file_links, selected_url_links, commit)
    # Folders
    selected_folders.each do |id|
      raise DmsfAccessError unless User.current.allowed_to?(:folder_manipulation, @project)
      folder = DmsfFolder.find_by(id: id)
      if folder
        unless folder.delete commit
          flash[:errors] = folder.errors.full_messages.to_sentence
          return
        end
      elsif !commit
        raise FileNotFound
      end
    end
    # Files
    deleted_files = []
    not_deleted_files = []
    selected_files.each do |id|
      file = DmsfFile.find_by(id: id)
      if file
        if file.delete(commit)
          deleted_files << file unless commit
        else
          not_deleted_files << file
        end
      elsif !commit
        raise FileNotFound
      end
    end
    # Activities
    unless deleted_files.empty?
      begin
        recipients = DmsfMailer.deliver_files_deleted(@project, deleted_files)
        if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
          if recipients.any?
            to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
            to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
            flash[:warning] = l(:warning_email_notifications, :to => to)
          end
        end
      rescue Exception => e
        Rails.logger.error "Could not send email notifications: #{e.message}"
      end
    end
    unless not_deleted_files.empty?
      flash[:warning] = l(:warning_some_entries_were_not_deleted, :entries => not_deleted_files.map{|e| e.title}.join(', '))
    end
    # Links
    (selected_dir_links + selected_file_links + selected_url_links).each do |id|
      link = DmsfLink.find_by(id: id)
      link.delete commit if link
    end
    if flash[:errors].blank? && flash[:warning].blank?
      flash[:notice] = l(:notice_entries_deleted)
    end
  end

  def find_folder
    @folder = DmsfFolder.find params[:folder_id] if params[:folder_id].present?
  rescue DmsfAccessError
    render_403
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_folder_by_title
    # find by title has to be scoped to project
    project = Project.find(params[:id])
    @folder = DmsfFolder.find_by(title: params[:folder_title], project_id: project.id) if params[:folder_title].present?
  rescue DmsfAccessError
    render_403
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_parent
    @parent = DmsfFolder.visible.find params[:parent_id] if params[:parent_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def tree_view
    tag = params[:custom_field_id].present? && params[:custom_value].present?
    @tree_view = (User.current.pref[:dmsf_tree_view] == '1') && (!%w(atom xml json).include?(params[:format])) && !tag
  end

  def copy_folder(folder)
    copy = folder.clone
    copy.id = folder.id
    copy
  end

  def get_display_params
    @system_folder = @folder && @folder.system
    @folder_manipulation_allowed = User.current.allowed_to?(:folder_manipulation, @project)
    @file_manipulation_allowed = User.current.allowed_to?(:file_manipulation, @project)
    @file_delete_allowed = User.current.allowed_to?(:file_delete, @project)
    @file_view_allowed = User.current.allowed_to?(:view_dmsf_files, @project)
    @force_file_unlock_allowed = User.current.allowed_to?(:force_file_unlock, @project)
    @workflows_available = DmsfWorkflow.where(['project_id = ? OR project_id IS NULL', @project.id]).exists?
    @file_approval_allowed = User.current.allowed_to?(:file_approval, @project)
    tag = params[:custom_field_id].present? && params[:custom_value].present?
    @extra_columns = [l(:label_last_approver), l(:field_project), l(:label_document_url), l(:label_last_revision_id)]
    if @tree_view
      @locked_for_user = false
    else
      if tag
        @subfolders = []
        @folder = nil
        DmsfFolder.where(project_id: @project.id, system: false).visible.find_each do |f|
          f.custom_field_values.each do |v|
            if v.custom_field_id == params[:custom_field_id].to_i
              if v.custom_field.compare_values?(v.value, params[:custom_value])
                @subfolders << f
                break
              end
            end
          end
        end
        @files = []
        DmsfFile.where(project_id: @project.id).visible.find_each do |f|
          r = f.last_revision
          if r
            r.custom_field_values.each do |v|
              if v.custom_field_id == params[:custom_field_id].to_i
                if v.custom_field.compare_values?(v.value, params[:custom_value])
                  @files << f
                  break
                end
              end
            end
          end
        end
        @dir_links = []
        DmsfLink.where(project_id: @project.id, target_type: DmsfFolder.model_name.to_s).where.not(
          target_id: nil).visible.find_each do |l|
          l.target_folder.custom_field_values.each do |v|
            if v.custom_field_id == params[:custom_field_id].to_i
              if v.custom_field.compare_values?(v.value, params[:custom_value])
                @dir_links << l
                break
              end
            end
          end
        end
        @file_links = []
        DmsfLink.where(project_id: @project.id, target_type: DmsfFile.model_name.to_s).visible.find_each do |l|
          r = l.target_file.last_revision if l.target_file
          if r
            r.custom_field_values.each do |v|
              if v.custom_field_id == params[:custom_field_id].to_i
                if v.custom_field.compare_values?(v.value, params[:custom_value])
                  @file_links << l
                  break
                end
              end
            end
          end
        end
        @url_links = []
      else
        scope = @folder ? @folder : @project
        @locked_for_user = @folder && @folder.locked_for_user?
        @subfolders = scope.dmsf_folders.visible
        @files = scope.dmsf_files.visible
        @dir_links = scope.folder_links.visible
        @file_links = scope.file_links.visible
        @url_links = scope.url_links.visible
        # Limit and offset for REST API calls
        if params[:limit].present?
          @subfolders = @subfolders.limit(params[:limit])
          @files = @files.limit(params[:limit])
          @dir_links = @dir_links.limit(params[:limit])
          @file_links = @file_links.limit(params[:limit])
          @url_links = @url_links.limit(params[:limit])
        end
        if params[:offset].present?
          @subfolders = @subfolders.offset(params[:offset])
          @files = @files.offset(params[:offset])
          @dir_links = @dir_links.offset(params[:offset])
          @file_links = @file_links.offset(params[:offset])
          @url_links = @url_links.offset(params[:offset])
        end
      end
      # Remove system folders you are not allowed to see because you are not allowed to see the issue or you are not
      # permitted to see system folders
      @subfolders = DmsfHelper.visible_folders(@subfolders, @project)
    end

    @ajax_upload_size = Setting.plugin_redmine_dmsf['dmsf_max_ajax_upload_filesize'].presence || 100

    # Trash
    @trash_visible = @folder_manipulation_allowed && @file_manipulation_allowed &&
      @file_delete_allowed && !@locked_for_user && !@folder
    @trash_enabled = DmsfFolder.deleted.where(project_id: @project.id).exists? ||
      DmsfFile.deleted.where(project_id: @project.id).exists? ||
      DmsfLink.deleted.where(project_id: @project.id).exists?
  end

end
