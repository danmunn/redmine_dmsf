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

# DMSF controller
class DmsfController < ApplicationController
  include RedmineDmsf::DmsfZip

  before_action :find_project, except: %i[expand_folder index digest reset_digest]
  before_action :authorize, except: %i[expand_folder index digest reset_digest]
  before_action :authorize_global, only: [:index]
  before_action :find_folder,
                except: %i[new create edit_root save_root add_email append_email autocomplete_for_user digest
                           reset_digest]
  before_action :find_parent, only: %i[new create delete]
  before_action :permissions
  # Also try to lookup folder by title if this is an API call
  before_action :find_folder_by_title, only: [:show]
  before_action :query, only: %i[expand_folder show trash empty_trash index]
  before_action :project_roles, only: %i[new edit create save]
  before_action :find_target_folder, only: %i[copymove entries_operation]
  before_action :check_target_folder, only: [:entries_operation]
  before_action :require_login, only: %i[digest reset_digest]

  accept_api_auth :show, :create, :save, :delete, :entries_operation

  helper :custom_fields
  helper :dmsf_folder_permissions
  helper :queries
  include QueriesHelper
  helper :dmsf_queries
  include DmsfQueriesHelper
  helper :context_menus
  helper :watchers

  def permissions
    if !DmsfFolder.permissions?(@folder, allow_system: false)
      render_403
    elsif @folder && @project && (@folder.project != @project)
      render_404
    end
    true
  end

  def expand_folder
    @idnt = params[:idnt].present? ? params[:idnt].to_i + 1 : 0
    @query.project = Project.find_by(id: params[:project_id]) if params[:project_id].present?
    @query.dmsf_folder_id = @folder&.id
    @query.deleted = false
    @query.sub_projects = true
    respond_to do |format|
      format.js { render action: 'query_rows' }
    end
  end

  def index
    @query.sub_projects = true
    show
  end

  def show
    @system_folder = @folder&.system
    @locked_for_user = @folder&.locked_for_user?
    @folder_manipulation_allowed = User.current.allowed_to?(:folder_manipulation, @project)
    @file_manipulation_allowed = User.current.allowed_to?(:file_manipulation, @project)
    @trash_enabled = @folder_manipulation_allowed && @file_manipulation_allowed
    @notifications = Setting.notified_events.include?('dmsf_legacy_notifications')
    @query.dmsf_folder_id = @folder ? @folder.id : nil
    @query.deleted = false
    @query.sub_projects |= Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders'].present?
    if @folder&.deleted? || (params[:folder_title].present? && !@folder)
      render_404
      return
    end
    if @query.valid?
      respond_to do |format|
        format.html do
          @dmsf_count = @query.dmsf_count
          @dmsf_pages = Paginator.new @dmsf_count, per_page_option, params['page']
          render layout: !request.xhr?
        end
        format.api { @offset, @limit = api_offset_and_limit }
        format.csv do
          send_data query_to_csv(@query.dmsf_nodes, @query), type: 'text/csv; header=present', filename: 'dmsf.csv'
        end
      end
    else
      respond_to do |format|
        format.html do
          @dmsf_count = 0
          @dmsf_pages = Paginator.new @dmsf_count, per_page_option, params['page']
          render layout: !request.xhr?
        end
        format.any(:atom, :csv, :pdf) { head :unprocessable_entity }
        format.api { render_validation_errors(@query) }
      end
    end
  end

  def trash
    @folder_manipulation_allowed = User.current.allowed_to? :folder_manipulation, @project
    @file_manipulation_allowed = User.current.allowed_to? :file_manipulation, @project
    @file_delete_allowed = User.current.allowed_to? :file_delete, @project
    @query.deleted = true
    respond_to do |format|
      format.html do
        @dmsf_count = @query.dmsf_count
        @dmsf_pages = Paginator.new @dmsf_count, per_page_option, params['page']
        render layout: !request.xhr?
      end
    end
  end

  def download_email_entries
    # IE has got a tendency to cache files
    expires_in 0.years, 'must-revalidate' => true
    send_file(
      params[:path],
      filename: 'Documents.zip',
      type: 'application/zip',
      disposition: 'attachment'
    )
  rescue StandardError => e
    flash[:error] = e.message
  end

  def copymove
    @ids = params[:ids].uniq
    member = Member.find_by(project_id: @project.id, user_id: User.current.id)
    @fast_links = member&.dmsf_fast_links
    unless @fast_links
      @projects = DmsfFolder.allowed_target_projects_on_copy
      @folders = DmsfFolder.directory_tree(@target_project)
      @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) if params[:target_folder_id].present?
    end
    @back_url = params[:back_url]
    render layout: !request.xhr?
  end

  def entries_operation
    # Download/Email
    if @selected_folders.blank? && @selected_files.blank? && @selected_links.blank?
      flash[:warning] = l(:warning_no_entries_selected)
      redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
      return
    end

    if @selected_dir_links.present? && (params[:email_entries].present? || params[:download_entries].present?)
      @selected_folders = DmsfLink.where(id: selected_dir_links).pluck(:target_id) | @selected_folders
    end

    if @selected_file_links.present? && (params[:email_entries].present? || params[:download_entries].present?)
      @selected_files = DmsfLink.where(id: selected_file_links).pluck(:target_id) | @selected_files
    end

    begin
      if params[:email_entries].present?
        email_entries @selected_folders, @selected_files
      elsif params[:restore_entries].present?
        restore_entries @selected_folders, @selected_files, @selected_links
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
      elsif params[:delete_entries].present?
        delete_entries @selected_folders, @selected_files, @selected_links, false
        redirect_back_or_default dmsf_folder_path id: @project, folder_id: @folder
      elsif params[:destroy_entries].present?
        delete_entries @selected_folders, @selected_files, @selected_links, true
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
      elsif params[:move_entries].present?
        move_entries @selected_folders, @selected_files, @selected_links
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
      elsif params[:copy_entries].present?
        copy_entries @selected_folders, @selected_files, @selected_links
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
      else
        download_entries @selected_folders, @selected_files
      end
    rescue RedmineDmsf::Errors::DmsfFileNotFoundError
      render_404
    rescue RedmineDmsf::Errors::DmsfAccessError
      render_403
    rescue StandardError => e
      flash[:error] = e.message
      Rails.logger.error e.message
      redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
    end
  end

  def entries_email
    if params[:email][:to].strip.blank?
      flash[:error] = l(:error_email_to_must_be_entered)
    else
      DmsfMailer.deliver_send_documents @project, params[:email].permit!, User.current
      if File.exist?(params[:email][:zipped_content])
        File.delete(params[:email][:zipped_content])
      else
        flash[:error] = l(:header_minimum_filesize)
      end
      flash[:notice] = l(:notice_email_sent, params[:email][:to])
    end
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def new
    @folder = DmsfFolder.new
    @pathfolder = @parent
    render action: 'edit'
  end

  def edit
    @parent = @folder.dmsf_folder
    @pathfolder = copy_folder(@folder)
    @force_file_unlock_allowed = User.current.allowed_to?(:force_file_unlock, @project)
    @redirect_to_folder_id = params[:redirect_to_folder_id]
    @notifications = Setting.notified_events.include?('dmsf_legacy_notifications')
  end

  def edit_root
    @notifications = Setting.notified_events.include?('dmsf_legacy_notifications')
  end

  def create
    @folder = DmsfFolder.new
    @folder.project = @project
    @folder.user = User.current
    saved = @folder.update_from_params(params)
    respond_to do |format|
      format.js
      format.api { render_validation_errors(@folder) unless saved }
      format.html do
        if saved
          flash[:notice] = l(:notice_folder_created)
          redirect_to dmsf_folder_path(id: @project, folder_id: @folder.dmsf_folder)
        else
          @pathfolder = @parent
          render action: 'edit'
        end
      end
    end
  end

  def save
    unless params[:dmsf_folder]
      redirect_to dmsf_folder_path(id: @project, folder_id: @folder)
      return
    end
    @pathfolder = copy_folder(@folder)
    saved = @folder.update_from_params(params)
    respond_to do |format|
      format.api { render_validation_errors(@folder) unless saved }
      format.html do
        if saved
          flash[:notice] = l(:notice_folder_details_were_saved)
          if @folder.project == @project
            redirect_to_folder_id = params[:dmsf_folder][:redirect_to_folder_id]
            redirect_to_folder_id = @folder.dmsf_folder.id if @folder.dmsf_folder && redirect_to_folder_id.blank?
          end
          redirect_to dmsf_folder_path(id: @project, folder_id: redirect_to_folder_id)
        else
          render action: 'edit'
        end
      end
    end
  end

  def delete
    commit = params[:commit] == 'yes'
    result = @folder.delete(commit: commit)
    if result
      flash[:notice] = l(:notice_folder_deleted)
    else
      flash[:error] = @folder.errors.full_messages.to_sentence
    end
    respond_to do |format|
      format.html do
        if commit
          redirect_to trash_dmsf_path(@project)
        else
          redirect_to dmsf_folder_path(id: @project, folder_id: @parent)
        end
      end
      format.api { result ? render_api_ok : render_validation_errors(@folder) }
    end
  end

  def restore
    if @folder.restore
      flash[:notice] = l(:notice_dmsf_folder_restored)
    else
      flash[:error] = @folder.errors.full_messages.to_sentence
    end
    redirect_to trash_dmsf_path(@project)
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
    redirect_to dmsf_folder_path(id: @project)
  end

  def notify_activate
    if @folder&.notification || (@folder.nil? && @project.dmsf_notification)
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
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
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
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
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
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def unlock
    if @folder.nil?
      flash[:warning] = l(:warning_foler_unlockable)
    elsif !@folder.locked?
      flash[:warning] = l(:warning_folder_not_locked)
    elsif @folder.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @project)
      @folder.unlock!
      flash[:notice] = l(:notice_folder_unlocked)
    else
      flash[:error] = l(:error_only_user_that_locked_folder_can_unlock_it)
    end
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
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

  # Move the dragged object to the given destination
  def drop
    result = false
    object = nil
    if params[:dmsf_folder].present? &&
       params[:dmsf_folder][:drag_id].present? &&
       params[:dmsf_folder][:drop_id].present? &&
       params[:dmsf_folder][:drag_id] =~ /(.+)-(\d+)/
      type = Regexp.last_match(1)
      id = Regexp.last_match(2)
      if params[:dmsf_folder][:drop_id] =~ /^(\d+)(p|f)span$/
        case type
        when 'file'
          object = DmsfFile.find_by(id: id)
        when 'folder'
          object = DmsfFolder.find_by(id: id)
        when 'file-link', 'folder-link', 'url-link'
          object = DmsfLink.find_by(id: id)
        end
        if object
          case Regexp.last_match(2)
          when 'p'
            project = Project.find_by(id: Regexp.last_match(1))
            if project &&
               User.current.allowed_to?(:file_manipulation, project) &&
               User.current.allowed_to?(:folder_manipulation, project)
              result = object.move_to(project, nil)
            end
          when 'f'
            dmsf_folder = DmsfFolder.find_by(id: Regexp.last_match(1))
            if dmsf_folder
              if dmsf_folder == object.dmsf_folder
                object.errors.add(:base, l(:error_target_folder_same))
              elsif object.dmsf_folder&.locked_for_user?
                object.errors.add(:base, l(:error_folder_is_locked))
              else
                result = object.move_to(dmsf_folder.project, dmsf_folder)
              end
            end
          end
        end
      end
    end
    respond_to do |format|
      if result
        format.js { head :ok }
      else
        format.js do
          if object
            flash.now[:error] = object.errors.full_messages.to_sentence
          else
            head :unprocessable_entity
          end
        end
      end
    end
  end

  def empty_trash
    @query.deleted = true
    @query.dmsf_nodes.each do |node|
      case node.type
      when 'folder'
        folder = DmsfFolder.find_by(id: node.id)
        folder&.delete commit: true
      when 'file'
        file = DmsfFile.find_by(id: node.id)
        file&.delete commit: true
      when /link$/
        link = DmsfLink.find_by(id: node.id)
        link&.delete commit: true
      end
    end
    redirect_back_or_default trash_dmsf_path id: @project
  end

  # Reset WebDAV digest
  def digest; end

  def reset_digest
    if request.post?
      raise StandardError, l(:notice_account_wrong_password) unless User.current.check_password?(params[:password])

      # We have to create a token first to prevent an autogenerated token's value
      token = Token.create!(user_id: User.current.id, action: 'dmsf_webdav_digest')
      token.value = ActiveSupport::Digest.hexdigest(
        "#{User.current.login}:#{RedmineDmsf::Webdav::AUTHENTICATION_REALM}:#{params[:password]}"
      )
      token.save
      flash[:notice] = l(:notice_webdav_digest_reset)
    end
  rescue StandardError => e
    flash[:error] = e.message
  ensure
    redirect_to my_account_path
  end

  private

  def users_for_new_users
    User.active.visible.member_of(@project).like(params[:q]).order(:type, :lastname).to_a
  end

  def email_entries(selected_folders, selected_files)
    raise RedmineDmsf::Errors::DmsfAccessError unless User.current.allowed_to?(:email_documents, @project)

    zip = Zip.new
    zip_entries(zip, selected_folders, selected_files)
    zipped_content = zip.finish

    max_filesize = Setting.plugin_redmine_dmsf['dmsf_max_email_filesize'].to_f
    if max_filesize.positive? && File.size(zipped_content) > max_filesize * 1_048_576
      raise RedmineDmsf::Errors::DmsfEmailMaxFileSizeError
    end

    zip.dmsf_files.each do |f|
      # Action
      audit = DmsfFileRevisionAccess.new
      audit.user = User.current
      audit.dmsf_file_revision = f.last_revision
      audit.action = DmsfFileRevisionAccess::EMAIL_ACTION
      audit.save!
    end

    # Notification
    begin
      DmsfMailer.deliver_files_downloaded @project, zip.dmsf_files, request.remote_ip
    rescue StandardError => e
      Rails.logger.error "Could not send email notifications: #{e.message}"
    end

    @email_params = {
      zipped_content: zipped_content,
      folders: selected_folders,
      files: selected_files,
      subject: "#{@project.name} #{l(:label_dmsf_file_plural).downcase}",
      from: Setting.plugin_redmine_dmsf['dmsf_documents_email_from'].presence ||
            "#{User.current.name} <#{User.current.mail}>",
      reply_to: Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to']
    }
    @back_url = params[:back_url]
    render action: 'email_entries'
  ensure
    zip&.close
  end

  def download_entries(selected_folders, selected_files)
    zip = Zip.new
    zip_entries(zip, selected_folders, selected_files)
    zip.dmsf_files.each do |f|
      # Action
      audit = DmsfFileRevisionAccess.new
      audit.user = User.current
      audit.dmsf_file_revision = f.last_revision
      audit.action = DmsfFileRevisionAccess::DOWNLOAD_ACTION
      audit.save!
    end
    # Notifications
    begin
      DmsfMailer.deliver_files_downloaded @project, zip.dmsf_files, request.remote_ip
    rescue StandardError => e
      Rails.logger.error "Could not send email notifications: #{e.message}"
    end
    send_file(
      zip.finish,
      filename: filename_for_content_disposition("#{@project.name}-#{DateTime.current.strftime('%y%m%d%H%M%S')}.zip"),
      type: 'application/zip',
      disposition: 'attachment'
    )
  ensure
    zip&.close
  end

  def zip_entries(zip, selected_folders, selected_files)
    member = Member.find_by(user_id: User.current.id, project_id: @project.id)
    selected_folders.each do |selected_folder_id|
      folder = DmsfFolder.visible.find_by(id: selected_folder_id)
      raise RedmineDmsf::Errors::DmsfFileNotFoundError unless folder

      zip.add_dmsf_folder folder, member, folder&.dmsf_folder&.dmsf_path_str
    end
    selected_files.each do |selected_file_id|
      file = DmsfFile.visible.find_by(id: selected_file_id)
      unless file&.last_revision && File.exist?(file.last_revision&.disk_file)
        raise RedmineDmsf::Errors::DmsfFileNotFoundError
      end
      unless (file.project == @project) || User.current.allowed_to?(:view_dmsf_files, file.project)
        raise RedmineDmsf::Errors::DmsfAccessError
      end

      zip.add_dmsf_file file, member, file.dmsf_folder&.dmsf_path_str
    end
    max_files = Setting.plugin_redmine_dmsf['dmsf_max_file_download'].to_i
    raise RedmineDmsf::Errors::DmsfZipMaxFilesError if max_files.positive? && zip.dmsf_files.length > max_files

    zip
  end

  def restore_entries(selected_folders, selected_files, selected_links)
    # Folders
    selected_folders.each do |id|
      folder = DmsfFolder.find_by(id: id)

      raise RedmineDmsf::Errors::DmsfFileNotFoundError unless folder
    end
    # Files
    selected_files.each do |id|
      file = DmsfFile.find_by(id: id)
      raise RedmineDmsf::Errors::DmsfFileNotFoundError unless file

      flash[:error] = file.errors.full_messages.to_sentence unless file.restore
    end
    # Links
    selected_links.each do |id|
      link = DmsfLink.find_by(id: id)
      raise RedmineDmsf::Errors::DmsfFileNotFoundError unless link

      flash[:error] = link.errors.full_messages.to_sentence unless link.restore
    end
  end

  def delete_entries(selected_folders, selected_files, selected_links, commit)
    # Folders
    selected_folders.each do |id|
      raise RedmineDmsf::Errors::DmsfAccessError unless User.current.allowed_to?(:folder_manipulation, @project)

      folder = DmsfFolder.find_by(id: id)
      if folder
        raise StandardError, folder.errors.full_messages.to_sentence unless folder.delete(commit: commit)
      elsif !commit
        raise RedmineDmsf::Errors::DmsfFileNotFoundError
      end
    end
    # Files
    deleted_files = []
    not_deleted_files = []
    if selected_files.any?
      raise RedmineDmsf::Errors::DmsfAccessError unless User.current.allowed_to?(:file_delete, @project)

      selected_files.each do |id|
        file = DmsfFile.find_by(id: id)
        if file
          if file.delete(commit: commit)
            deleted_files << file unless commit
          else
            not_deleted_files << file
          end
        elsif !commit
          raise RedmineDmsf::Errors::DmsfFileNotFoundError
        end
      end
    end
    # Activities
    unless deleted_files.empty?
      begin
        recipients = DmsfMailer.deliver_files_deleted(@project, deleted_files)
        if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] && recipients.any?
          max_receivers = Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i
          to = recipients.collect { |user, _| user.name }.first(max_receivers).join(', ')
          if to.present?
            to << (recipients.count > max_receivers ? ',...' : '.')
            flash[:warning] = l(:warning_email_notifications, to: to)
          end
        end
      rescue StandardError => e
        Rails.logger.error "Could not send email notifications: #{e.message}"
      end
    end
    unless not_deleted_files.empty?
      flash[:warning] = l(:warning_some_entries_were_not_deleted, entries: not_deleted_files.map(&:title).join(', '))
    end
    # Links
    if selected_links.any?
      raise RedmineDmsf::Errors::DmsfAccessError unless User.current.allowed_to?(:folder_manipulation, @project)

      selected_links.each do |id|
        link = DmsfLink.find_by(id: id)
        link&.delete commit: commit
      end
    end
    flash[:notice] = l(:notice_entries_deleted) if flash[:error].blank? && flash[:warning].blank?
  end

  def copy_entries(selected_folders, selected_files, selected_links)
    # Folders
    selected_folders.each do |id|
      folder = DmsfFolder.find_by(id: id)
      new_folder = folder.copy_to(@target_project, @target_folder)
      raise(StandardError, new_folder.errors.full_messages.to_sentence) unless new_folder.errors.empty?
    end
    # Files
    selected_files.each do |id|
      file = DmsfFile.find_by(id: id)
      new_file = file.copy_to(@target_project, @target_folder)
      raise(StandardError, new_file.errors.full_messages.to_sentence) unless new_file.errors.empty?
    end
    # Links
    selected_links.each do |id|
      link = DmsfLink.find_by(id: id)
      new_link = link.copy_to(@target_project, @target_folder)
      raise(StandardError, new_link.errors.full_messages.to_sentence) unless new_link.errors.empty?
    end
    flash[:notice] = l(:notice_entries_copied) if flash[:error].blank? && flash[:warning].blank?
  end

  def move_entries(selected_folders, selected_files, selected_links)
    # Permissions
    if selected_folders.any? && !User.current.allowed_to?(:folder_manipulation, @project)
      raise RedmineDmsf::Errors::DmsfAccessError
    end
    if (selected_folders.any? || selected_links.any?) && !User.current.allowed_to?(:file_manipulation, @project)
      raise RedmineDmsf::Errors::DmsfAccessError
    end

    # Folders
    selected_folders.each do |id|
      folder = DmsfFolder.find_by(id: id)
      unless folder.move_to(@target_project, @target_folder)
        raise(StandardError, folder.errors.full_messages.to_sentence)
      end
    end
    # Files
    selected_files.each do |id|
      file = DmsfFile.find_by(id: id)
      raise(StandardError, file.errors.full_messages.to_sentence) unless file.move_to(@target_project, @target_folder)
    end
    # Links
    selected_links.each do |id|
      link = DmsfLink.find_by(id: id)
      raise(StandardError, link.errors.full_messages.to_sentence) unless link.move_to(@target_project, @target_folder)
    end
    flash[:notice] = l(:notice_entries_moved) if flash[:error].blank? && flash[:warning].blank?
  end

  def find_folder
    @folder = DmsfFolder.find(params[:folder_id]) if params[:folder_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_folder_by_title
    return unless api_request? && !@folder && params[:folder_title].present?

    @folder = DmsfFolder.find_by(title: params[:folder_title], project_id: @project.id)
    render_404 unless @folder
  end

  def find_parent
    @parent = DmsfFolder.visible.find params[:parent_id] if params[:parent_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def copy_folder(folder)
    copy = folder.clone
    copy.id = folder.id
    copy
  end

  def query
    retrieve_default_query true
    @query = if Redmine::Plugin.installed?('easy_extensions')
               retrieve_query_without_easy_extensions DmsfQuery, true
             else
               retrieve_query DmsfQuery, true
             end
  end

  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end
    if !params[:set_filter] && use_session && session[:issue_query]
      query_id, project_id = session[:issue_query].values_at(:id, :project_id)
      return if DmsfQuery.exists?(id: query_id) && project_id == @project&.id
    end
    default_query = DmsfQuery.default(project: @project)
    return unless default_query

    params[:query_id] = default_query.id
  end

  def project_roles
    @project_roles = Role.givable.joins(:member_roles).joins(:members).where(members: { project_id: @project.id })
                         .distinct
  end

  def find_target_folder
    @target_project = if params[:dmsf_entries] && params[:dmsf_entries][:target_project_id].present?
                        Project.find params[:dmsf_entries][:target_project_id]
                      else
                        @project
                      end
    if params[:dmsf_entries] && params[:dmsf_entries][:target_folder_id].present?
      target_folder_id = params[:dmsf_entries][:target_folder_id]
      @target_folder = DmsfFolder.find(target_folder_id)
      raise ActiveRecord::RecordNotFound unless DmsfFolder.visible.exists?(id: target_folder_id)

      @target_project = @target_folder&.project
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_target_folder
    if params[:ids].present?
      @selected_folders = params[:ids].grep(/folder-\d+/).map { |x| Regexp.last_match(1).to_i if x =~ /folder-(\d+)/ }
      @selected_files = params[:ids].grep(/file-\d+/).map { |x| Regexp.last_match(1).to_i if x =~ /file-(\d+)/ }
      @selected_dir_links = params[:ids].grep(/folder-link-\d+/)
                                        .map { |x| Regexp.last_match(1).to_i if x =~ /folder-link-(\d+)/ }
      @selected_file_links = params[:ids].grep(/file-link-\d+/)
                                         .map { |x| Regexp.last_match(1).to_i if x =~ /file-link-(\d+)/ }
      @selected_url_links = params[:ids].grep(/url-link-\d+/)
                                        .map { |x| Regexp.last_match(1).to_i if x =~ /url-link-(\d+)/ }
      @selected_links = @selected_dir_links + @selected_file_links + @selected_url_links
    else
      @selected_folders = []
      @selected_files = []
      @selected_links = []
    end
    return unless params[:copy_entries].present? || params[:move_entries].present?

    begin
      # Prevent copying/moving to the same destination
      folders = DmsfFolder.where(id: @selected_folders).to_a
      files = DmsfFile.where(id: @selected_files).to_a
      links = DmsfLink.where(id: @selected_links).to_a
      (folders + files + links).each do |entry|
        if entry.dmsf_folder
          raise RedmineDmsf::Errors::DmsfParentError if entry.dmsf_folder == @target_folder || entry == @target_folder
        elsif @target_folder.nil?
          raise RedmineDmsf::Errors::DmsfParentError if entry.project == @target_project
        end
      end
      # Prevent recursion
      if params[:move_entries].present?
        folders.each do |entry|
          raise RedmineDmsf::Errors::DmsfParentError if entry.any_child?(@target_folder)
        end
      end
      # Check permissions
      if (@target_folder && (@target_folder.locked_for_user? ||
         !DmsfFolder.permissions?(@target_folder, allow_system: false))) ||
         !@target_project.allows_to?(:folder_manipulation)
        raise RedmineDmsf::Errors::DmsfAccessError
      end
    rescue RedmineDmsf::Errors::DmsfParentError
      flash[:error] = l(:error_target_folder_same)
      redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
    rescue RedmineDmsf::Errors::DmsfAccessError
      render_403
    end
  end
end
