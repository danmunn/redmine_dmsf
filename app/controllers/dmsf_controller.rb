# encoding: utf-8
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

class DmsfController < ApplicationController
  unloadable

  before_action :find_project
  before_action :authorize, :except => [:expand_folder]
  before_action :find_folder, :except => [:new, :create, :edit_root, :save_root]
  before_action :find_parent, :only => [:new, :create]
  before_action :tree_view, :only => [:delete, :show]
  before_action :permissions

  accept_api_auth :show, :create, :save

  skip_before_action :verify_authenticity_token,  if: -> { request.headers['HTTP_X_REDMINE_API_KEY'].present? }

  helper :all
  helper :dmsf_folder_permissions

  def permissions
    render_403 unless DmsfFolder.permissions?(@folder)
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
        filename << DateTime.now.strftime('_%Y%m%d%H%M%S.csv')
        send_data(DmsfHelper.dmsf_to_csv(@folder ? @folder : @project, params[:settings][:dmsf_columns]),
                  :type => 'text/csv; header=present', :filename => filename)
      }
    end
  end

  def trash
    @folder_manipulation_allowed = User.current.allowed_to? :folder_manipulation, @project
    @file_manipulation_allowed = User.current.allowed_to? :file_manipulation, @project
    @file_delete_allowed = User.current.allowed_to? :file_delete, @project
    @subfolders = DmsfFolder.deleted.where(:project_id => @project.id)
    @files = DmsfFile.deleted.where(:project_id => @project.id)
    @dir_links = DmsfLink.deleted.where(:project_id => @project.id, :target_type => DmsfFolder.model_name.to_s)
    @file_links = DmsfLink.deleted.where(:project_id => @project.id, :target_type => DmsfFile.model_name.to_s)
    @url_links = DmsfLink.deleted.where(:project_id => @project.id, :target_type => 'DmsfUrl')
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
      flash[:error] = e.message
  end

  def entries_operation
    # Download/Email
    selected_folders = params[:subfolders] || []
    selected_files = params[:files] || []
    selected_dir_links = params[:dir_links] || []
    selected_file_links = params[:file_links] || []
    selected_url_links = params[:url_links] || []

    if selected_folders.blank? && selected_files.blank? &&
      selected_dir_links.blank? && selected_file_links.blank? &&
      selected_url_links.blank?
      flash[:warning] = l(:warning_no_entries_selected)
      redirect_to :back
      return
    end

    if selected_dir_links.present? &&
      (params[:email_entries].present? || params[:download_entries].present?)
        selected_dir_links.each do |id|
          link = DmsfLink.find_by_id id
          selected_folders << link.target_id if link && !selected_folders.include?(link.target_id.to_s)
      end
    end

    if selected_file_links.present? &&
      (params[:email_entries].present? || params[:download_entries].present?)
        selected_file_links.each do |id|
          link = DmsfLink.find_by_id id
          selected_files << link.target_id if link && !selected_files.include?(link.target_id.to_s)
      end
    end

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
  rescue Exception => e
    flash[:error] = e.message
    Rails.logger.error e.message
    redirect_to :back
  end

  def tag_changed
    # Tag filter
    if params[:dmsf_folder] && params[:dmsf_folder][:custom_field_values].present?
      redirect_to dmsf_folder_path(
        :id => @project,
        :folder_id => @folder,
        :custom_field_id => params[:dmsf_folder][:custom_field_values].first[0],
        :custom_value => params[:dmsf_folder][:custom_field_values].first[1])
    else
      redirect_to :back
    end
  end

  def entries_email
    if params[:email][:to].strip.blank?
      flash[:error] = l(:error_email_to_must_be_entered)
    else
      DmsfMailer.send_documents(@project, User.current, params[:email]).deliver
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
    @users = Principal.active.where(:id => @folder.dmsf_folder_permissions.users.map{ |p| p.object_id })
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
    if @folder.delete(commit)
      flash[:notice] = l(:notice_folder_deleted)
    else
      flash[:error] = @folder.errors.full_messages.to_sentence
    end
    if commit || @tree_view
      redirect_to :back
    else
      redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder.dmsf_folder)
    end
  end

  def restore
    if @folder.restore
      flash[:notice] = l(:notice_dmsf_folder_restored)
    else
      flash[:error] = @folder.errors.full_messages.to_sentence
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
        flash[:error] = @project.errors.full_messages.to_sentence
      end
    end
    redirect_to dmsf_folder_path(:id => @project)
  end

  def notify_activate
    if((@folder && @folder.notification) || (@folder.nil? && @project.dmsf_notification))
      flash[:warning] = l(:warning_folder_notifications_already_activated)
    else
      if @folder
        @folder.notify_activate
      else
        @project.dmsf_notification = true
        @project.save
      end
      flash[:notice] = l(:notice_folder_notifications_activated)
    end
    redirect_to :back
  end

  def notify_deactivate
    if((@folder && !@folder.notification) || (@folder.nil? && !@project.dmsf_notification))
      flash[:warning] = l(:warning_folder_notifications_already_deactivated)
    else
      if @folder
        @folder.notify_deactivate
      else
        @project.dmsf_notification = nil
        @project.save
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
        flash[:error] = l(:error_only_user_that_locked_folder_can_unlock_it)
      end
    end
     redirect_to :back
  end

  private

  def log_activity(file, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{file.project.identifier}/#{file.id}"
  end

  def email_entries(selected_folders, selected_files)
    begin
      zip = DmsfZip.new
      zip_entries(zip, selected_folders, selected_files)

      zipped_content = "#{DmsfHelper.temp_dir}/#{DmsfHelper.temp_filename('dmsf_email_sent_documents.zip')}";

      File.open(zipped_content, 'wb') do |f|
        zip_file = File.open(zip.finish, 'rb')
        while (buffer = zip_file.read(8192))
          f.write(buffer)
        end
      end

      max_filesize = Setting.plugin_redmine_dmsf['dmsf_max_email_filesize'].to_f
      if max_filesize > 0 && File.size(zipped_content) > max_filesize * 1048576
        raise EmailMaxFileSize
      end

      zip.files.each do |f|
        log_activity(f, 'emailing zip')
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
        :from => "#{User.current.name} <#{User.current.mail}>"
      }
      render :action => 'email_entries'
    rescue Exception
      raise
    ensure
      zip.close if zip
    end
  end

  def download_entries(selected_folders, selected_files)
    begin
      zip = DmsfZip.new
      zip_entries(zip, selected_folders, selected_files)

      zip.files.each do |f|
        log_activity(f, 'download zip')
        audit = DmsfFileRevisionAccess.new
        audit.user = User.current
        audit.dmsf_file_revision = f.last_revision
        audit.action = DmsfFileRevisionAccess::DownloadAction
        audit.save!
      end

      send_file(zip.finish,
        :filename => filename_for_content_disposition("#{@project.name}-#{DateTime.now.strftime('%y%m%d%H%M%S')}.zip"),
        :type => 'application/zip',
        :disposition => 'attachment')
    rescue Exception
      raise
    ensure
      zip.close if zip
    end
  end

  def zip_entries(zip, selected_folders, selected_files)
    member = Member.where(:user_id => User.current.id, :project_id => @project.id).first
    if selected_folders && selected_folders.is_a?(Array)
      selected_folders.each do |selected_folder_id|
        folder = DmsfFolder.visible.find_by_id selected_folder_id
        if folder
          zip.add_folder(folder, member, (folder.dmsf_folder.dmsf_path_str if folder.dmsf_folder))
        else
          raise FileNotFound
        end
      end
    end
    if selected_files && selected_files.is_a?(Array)
      selected_files.each do |selected_file_id|
        file = DmsfFile.visible.find_by_id selected_file_id
        unless file && file.last_revision && File.exist?(file.last_revision.disk_file)
          raise FileNotFound
        end
        unless (file.project == @project) || User.current.allowed_to?(:view_dmsf_files, file.project)
          raise DmsfAccessError
        end
        zip.add_file(file, member, (file.dmsf_folder.dmsf_path_str if file.dmsf_folder)) if file
      end
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
      folder = DmsfFolder.find_by_id id
      if folder
        unless folder.restore
          flash[:error] = folder.errors.full_messages.to_sentence
        end
      else
        raise FileNotFound
      end
    end
    # Files
    selected_files.each do |id|
      file = DmsfFile.find_by_id id
      if file
        unless file.restore
          flash[:error] = file.errors.full_messages.to_sentence
        end
      else
        raise FileNotFound
      end
    end
    # Links
    (selected_dir_links + selected_file_links + selected_url_links).each do |id|
      link = DmsfLink.find_by_id id
      if link
        unless link.restore
          flash[:error] = link.errors.full_messages.to_sentence
        end
      else
        raise FileNotFound
      end
    end
  end

  def delete_entries(selected_folders, selected_files, selected_dir_links, selected_file_links, selected_url_links, commit)
    # Folders
    selected_folders.each do |id|
      folder = DmsfFolder.find_by_id id
      if folder
        unless folder.delete commit
          flash[:error] = folder.errors.full_messages.to_sentence
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
      file = DmsfFile.find_by_id id
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
    if !deleted_files.empty?
      deleted_files.each do |f|
        log_activity(f, 'deleted')
      end
      begin
        recipients = DmsfMailer.get_notify_users(@project, deleted_files)
        recipients.each do |u|
          DmsfMailer.files_deleted(u, @project, deleted_files).deliver
        end
        if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] == '1'
          unless recipients.empty?
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
      link = DmsfLink.find_by_id id
      link.delete commit if link
    end
    if flash[:error].blank? && flash[:warning].blank?
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
  rescue DmsfAccessError
    render_403
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

  private

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
        folder_id = @folder.id if @folder
        DmsfFolder.where(:project_id => @project.id, :dmsf_folder_id => folder_id, :system => false).visible.each do |f|
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
        DmsfFile.where(:project_id => @project.id, :dmsf_folder_id => folder_id).visible.each do |f|
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
        DmsfLink.where(:project_id => @project.id, :target_type => DmsfFolder.model_name.to_s, :dmsf_folder_id => folder_id).where('target_id IS NOT NULL').visible.each do |l|
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
        DmsfLink.where(:project_id => @project.id, :target_type => DmsfFile.model_name.to_s, :dmsf_folder_id => folder_id).visible.each do |l|
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
        if @folder
          @subfolders = @folder.dmsf_folders.visible.to_a
          @files = @folder.dmsf_files.visible
          @dir_links = @folder.folder_links.visible
          @file_links = @folder.file_links.visible
          @url_links = @folder.url_links.visible
          @locked_for_user = @folder.locked_for_user?
        else
          @subfolders = @project.dmsf_folders.visible.to_a
          @files = @project.dmsf_files.visible
          @dir_links = @project.folder_links.visible
          @file_links = @project.file_links.visible
          @url_links = @project.url_links.visible
          @locked_for_user = false
        end
      end
      # Remove system folders you are not allowed to see because you are not allowed to see the issue
      @subfolders = DmsfHelper.visible_folders(@subfolders, @project)
    end

    @ajax_upload_size = Setting.plugin_redmine_dmsf['dmsf_max_ajax_upload_filesize'].present? ? Setting.plugin_redmine_dmsf['dmsf_max_ajax_upload_filesize'] : 100

    # Trash
    @trash_visible = @folder_manipulation_allowed && @file_manipulation_allowed &&
      @file_delete_allowed && !@locked_for_user && !@folder
    @trash_enabled = DmsfFolder.deleted.where(:project_id => @project.id).any? ||
      DmsfFile.deleted.where(:project_id => @project.id).any? ||
      DmsfLink.deleted.where(:project_id => @project.id).any?
  end

end

