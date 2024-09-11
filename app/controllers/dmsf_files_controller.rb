# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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

# Files controller
class DmsfFilesController < ApplicationController
  menu_item :dmsf

  before_action :find_file, except: %i[delete_revision obsolete_revision]
  before_action :find_revision, only: %i[delete_revision obsolete_revision]
  before_action :find_folder, only: %i[delete create_revision]
  before_action :authorize
  before_action :permissions

  accept_api_auth :show, :view, :delete, :create_revision

  helper :custom_fields
  helper :dmsf_workflows
  helper :dmsf
  helper :queries
  helper :watchers
  helper :context_menus

  include QueriesHelper

  def permissions
    render_403 if @file && !DmsfFolder.permissions?(@file.dmsf_folder, allow_system: true, file: true)
    true
  end

  def view
    if params[:download].blank?
      @revision = @file.last_revision
    else
      @revision = DmsfFileRevision.find(params[:download].to_i)
      raise RedmineDmsf::Errors::DmsfAccessError if @revision.dmsf_file != @file
    end

    check_project @revision.dmsf_file
    raise ActionController::MissingFile if @file.deleted?

    # Action
    access = DmsfFileRevisionAccess.new
    access.user = User.current
    access.dmsf_file_revision = @revision
    access.action = DmsfFileRevisionAccess::DOWNLOAD_ACTION
    access.save!
    # Notifications
    begin
      DmsfMailer.deliver_files_downloaded @project, [@file], request.remote_ip
    rescue StandardError => e
      Rails.logger.error "Could not send email notifications: #{e.message}"
    end
    # Allow a preview of the file by an external plugin
    results = call_hook(:dmsf_files_controller_before_view, { file: @revision.disk_file })
    return if results.first == true

    member = Member.find_by(user_id: User.current.id, project_id: @file.project.id)
    # IE has got a tendency to cache files
    expires_in 0.years, 'must-revalidate' => true
    # PDF preview
    pdf_preview = (params[:disposition] != 'attachment') && params[:filename].blank? && @file.pdf_preview
    filename = filename_for_content_disposition(@revision.formatted_name(member))
    if !api_request? && pdf_preview.present? && (Setting.plugin_redmine_dmsf['office_bin'].present? ||
       params[:preview].present?)
      basename = File.basename(filename, '.*')
      send_file pdf_preview, filename: "#{basename}.pdf", type: 'application/pdf', disposition: 'inline'
    # Text preview
    elsif !api_request? && params[:download].blank? && (@file.size <= Setting.file_max_size_displayed.to_i.kilobyte) &&
          (@file.text? || @file.markdown? || @file.textile?) && !@file.html?
      @content = File.read(@revision.disk_file, mode: 'rb')
      render action: 'document'
    # Offer the file for download
    else
      params[:disposition] = 'attachment' if params[:filename].present?
      send_file @revision.disk_file,
                filename: filename,
                type: @revision.detect_content_type,
                disposition: params[:disposition].presence || @revision.dmsf_file.disposition
    end
  rescue RedmineDmsf::Errors::DmsfAccessError => e
    Rails.logger.error e.message
    render_403
  rescue StandardError => e
    Rails.logger.error e.message
    render_404
  end

  def show
    @revision = @file.last_revision
    @file_delete_allowed = User.current.allowed_to?(:file_delete, @project)
    @file_manipulation_allowed = User.current.allowed_to?(:file_manipulation, @project)
    @revision_count = @file.dmsf_file_revisions.visible.all.size
    @revision_pages = Paginator.new @revision_count, params['per_page'] ? params['per_page'].to_i : 25, params['page']
    @notifications = Setting.notified_events.include?('dmsf_legacy_notifications')

    respond_to do |format|
      format.html { render layout: !request.xhr? }
      format.api
    end
  end

  def create_revision
    if params[:dmsf_file_revision] && !@file.locked_for_user?
      revision = DmsfFileRevision.new
      revision.title = params[:dmsf_file_revision][:title].scrub.strip
      revision.name = params[:dmsf_file_revision][:name].scrub.strip
      revision.description = params[:dmsf_file_revision][:description]&.scrub&.strip
      revision.comment = params[:dmsf_file_revision][:comment].scrub.strip
      revision.dmsf_file = @file
      last_revision = @file.last_revision
      revision.source_revision = last_revision
      revision.user = User.current

      # Version
      revision.major_version = DmsfUploadHelper.db_version(params[:version_major])
      revision.minor_version = DmsfUploadHelper.db_version(params[:version_minor])
      revision.patch_version = DmsfUploadHelper.db_version(params[:version_patch])

      if params[:dmsf_attachments].present?
        keys = params[:dmsf_attachments].keys
        file_upload = params[:dmsf_attachments][keys.first] if keys&.first
      end
      if file_upload
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, file_upload)
        if upload
          revision.size = upload.size
          revision.disk_filename = revision.new_storage_filename
          revision.mime_type = upload.mime_type
          revision.digest = upload.digest
        end
      else
        revision.size = last_revision.size
        revision.disk_filename = last_revision.disk_filename
        revision.mime_type = last_revision.mime_type
        revision.digest = last_revision.digest
      end
      # Custom fields
      revision.copy_custom_field_values(params[:dmsf_file_revision][:custom_field_values], last_revision)
      @file.name = revision.name
      ok = true
      if revision.save
        revision.assign_workflow params[:dmsf_workflow_id]
        if upload
          begin
            FileUtils.mv upload.tempfile_path, revision.disk_file(search_if_not_exists: false)
          rescue StandardError => e
            Rails.logger.error e.message
            flash[:error] = e.message
            revision.destroy
            ok = false
          end
        end
        if ok && @file.locked? && !@file.locks.empty?
          begin
            @file.unlock!
            flash[:notice] = "#{l(:notice_file_unlocked)}, "
          rescue StandardError => e
            Rails.logger.error "Cannot unlock the file: #{e.message}"
            ok = false
          end
        end
        if ok && @file.save
          @file.last_revision = revision
          call_hook :dmsf_helper_upload_after_commit, { file: @file }
          begin
            recipients = DmsfMailer.deliver_files_updated(@project, [@file])
            if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] && recipients.any?
              max_notifications = Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i
              to = recipients.collect { |user, _| user.name }.first(max_notifications).join(', ')
              if to.present?
                to << (recipients.count > max_notifications ? ',...' : '.')
              end
            end
          rescue StandardError => e
            Rails.logger.error "Could not send email notifications: #{e.message}"
          end
        else
          ok = false
        end
      else
        ok = false
      end
    end

    respond_to do |format|
      format.html do
        flash[:error] = l(:error_file_is_locked) if @file.locked_for_user?
        flash[:warning] = l(:warning_email_notifications, to: to) if to.present?
        flash[:error] = @file.errors.full_messages.to_sentence if @file.errors.any?
        flash[:error] = revision.errors.full_messages.to_sentence if revision.errors.any?
        flash[:notice] = (flash[:notice].nil? ? '' : flash[:notice]) + l(:notice_file_revision_created) if ok
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
      end
      format.api
    end
  end

  def delete
    if @file
      commit = params[:commit] == 'yes'
      result = @file.delete(commit: commit)
      if result
        flash[:notice] = l(:notice_file_deleted)
        if commit
          container = @file.container
          container&.dmsf_file_removed @file
        else
          begin
            recipients = DmsfMailer.deliver_files_deleted(@project, [@file])
            if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] && recipients.any?
              max_notification = Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i
              to = recipients.collect { |user, _| user.name }.first(max_notification).join(', ')
              if to.present?
                to << (recipients.count > max_notification ? ',...' : '.')
                flash[:warning] = l(:warning_email_notifications, to: to)
              end
            end
          rescue StandardError => e
            Rails.logger.error "Could not send email notifications: #{e.message}"
          end
        end
      else
        msg = @file.errors.full_messages.to_sentence
        flash[:error] = msg
        Rails.logger.error msg
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder) }
      format.api { result ? render_api_ok : render_validation_errors(@file) }
    end
  end

  def delete_revision
    if @revision
      if @revision.delete commit: true
        if @file.name != @file.last_revision.name
          @file.name = @file.last_revision.name
          @file.save!
        end
        flash[:notice] = l(:notice_revision_deleted)
      else
        flash[:error] = @revision.errors.full_messages.to_sentence
      end
    end
    redirect_to action: 'show', id: @file
  end

  def obsolete_revision
    if @revision
      if @revision.obsolete
        flash[:notice] = l(:notice_revision_obsoleted)
      else
        flash[:error] = @revision.errors.full_messages.to_sentence
      end
    end
    redirect_to action: 'show', id: @file
  end

  def lock
    if @file.locked?
      flash[:warning] = l(:warning_file_already_locked)
    else
      begin
        @file.lock!
        flash[:notice] = l(:notice_file_locked)
      rescue StandardError => e
        flash[:error] = e.message
      end
    end
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def unlock
    if @file.locked?
      if @file.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @file.project)
        begin
          @file.unlock!
          flash[:notice] = l(:notice_file_unlocked)
        rescue StandardError => e
          flash[:error] = e.message
        end
      else
        flash[:error] = l(:error_only_user_that_locked_file_can_unlock_it)
      end
    else
      flash[:warning] = l(:warning_file_not_locked)
    end
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def notify_activate
    if @file.notification
      flash[:warning] = l(:warning_file_notifications_already_activated)
    else
      @file.notify_activate
      flash[:notice] = l(:notice_file_notifications_activated)
    end
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def notify_deactivate
    if @file.notification
      @file.notify_deactivate
      flash[:notice] = l(:notice_file_notifications_deactivated)
    else
      flash[:warning] = l(:warning_file_notifications_already_deactivated)
    end
    redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def restore
    if @file.restore
      flash[:notice] = l(:notice_dmsf_file_restored)
    else
      flash[:error] = @file.errors.full_messages.to_sentence
    end
    redirect_to trash_dmsf_path(@project)
  end

  def thumbnail
    if @file.image?
      tbnail = @file.thumbnail(size: params[:size])
      if tbnail
        if stale?(etag: tbnail)
          send_file tbnail,
                    filename: filename_for_content_disposition(@file.last_revision.disk_file),
                    type: @file.last_revision.detect_content_type,
                    disposition: 'inline'
        end
      else
        head :not_found
      end
    else
      head :not_found
    end
  end

  private

  def find_file
    @file = DmsfFile.find params[:id]
    @project = @file.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_revision
    @revision = DmsfFileRevision.visible.find params[:id]
    @file = @revision.dmsf_file
    @project = @file.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_folder
    @folder = DmsfFolder.find params[:folder_id] if params[:folder_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_project(entry)
    return unless entry && entry.project != @project

    raise RedmineDmsf::Errors::DmsfAccessError, l(:error_entry_project_does_not_match_current_project)
  end
end
