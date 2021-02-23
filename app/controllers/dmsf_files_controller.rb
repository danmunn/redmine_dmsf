# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFilesController < ApplicationController

  menu_item :dmsf

  before_action :find_file, except: [:delete_revision, :obsolete_revision]
  before_action :find_revision, only: [:delete_revision, :obsolete_revision]
  before_action :find_folder, only: [:delete, :create_revision]
  before_action :authorize
  before_action :permissions

  accept_api_auth :show, :view, :delete

  helper :custom_fields
  helper :dmsf_workflows
  helper :dmsf
  helper :queries

  include QueriesHelper

  def permissions
    if @file
      render_403 unless DmsfFolder.permissions?(@file.dmsf_folder)
    end
    true
  end

  def view
    begin
      if params[:download].blank?
        @revision = @file.last_revision
      else
        @revision = DmsfFileRevision.find(params[:download].to_i)
        raise DmsfAccessError if @revision.dmsf_file != @file
      end
      check_project @revision.dmsf_file
      raise ActionController::MissingFile if @file.deleted?
      access = DmsfFileRevisionAccess.new
      access.user = User.current
      access.dmsf_file_revision = @revision
      access.action = DmsfFileRevisionAccess::DownloadAction
      access.save!
      member = Member.find_by(user_id: User.current.id, project_id: @file.project.id)
      if member && !member.dmsf_title_format.nil? && !member.dmsf_title_format.empty?
        title_format = member.dmsf_title_format
      else
        title_format = Setting.plugin_redmine_dmsf['dmsf_global_title_format']
      end
      # IE has got a tendency to cache files
      expires_in(0.year, 'must-revalidate' => true)
      send_file @revision.disk_file,
        filename: filename_for_content_disposition(@revision.formatted_name(title_format)),
        type: @revision.detect_content_type,
        disposition: params[:disposition].present? ? params[:disposition] : @revision.dmsf_file.disposition
    rescue DmsfAccessError => e
      Rails.logger.error e.message
      render_403
    rescue => e
      Rails.logger.error e.message
      render_404
    end
  end

  def show
    @revision = @file.last_revision
    @file_delete_allowed = User.current.allowed_to?(:file_delete, @project)
    @file_manipulation_allowed = User.current.allowed_to?(:file_manipulation, @project)
    @revision_count = @file.dmsf_file_revisions.visible.all.size
    @revision_pages = Paginator.new @revision_count, params['per_page'] ? params['per_page'].to_i : 25, params['page']
    @wiki = Setting.text_formatting != 'HTML'

    respond_to do |format|
      format.html {
        render layout: !request.xhr?
      }
      format.api
    end
  end

  def create_revision
    if params[:dmsf_file_revision]
      if @file.locked_for_user?
        flash[:error] = l(:error_file_is_locked)
      else
        revision = DmsfFileRevision.new
        revision.title = params[:dmsf_file_revision][:title]
        revision.name = params[:dmsf_file_revision][:name]
        revision.description = params[:dmsf_file_revision][:description]
        revision.comment = params[:dmsf_file_revision][:comment]

        revision.dmsf_file = @file
        last_revision = @file.last_revision
        revision.source_revision = last_revision
        revision.user = User.current

        revision.major_version = last_revision.major_version
        revision.minor_version = last_revision.minor_version
        version = params[:version].to_i
        if version == 3
          revision.major_version = DmsfUploadHelper::db_version(params[:custom_version_major])
          revision.minor_version = DmsfUploadHelper::db_version(params[:custom_version_minor])
        else
           revision.increase_version(version)
        end
        file_upload = params[:dmsf_attachments]['1'] if params[:dmsf_attachments].present?
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
        end

        # Custom fields
        if params[:dmsf_file_revision][:custom_field_values].present?
          i = 0
          params[:dmsf_file_revision][:custom_field_values].each do |_, v|
            revision.custom_field_values[i].value = v
            i = i + 1
          end
        end

        @file.name = revision.name

        if revision.save
          revision.assign_workflow(params[:dmsf_workflow_id])
          if upload
            begin
              FileUtils.mv upload.tempfile_path, revision.disk_file(false)
            rescue => e
              Rails.logger.error e.message
              flash[:error] = e.message
              revision.destroy
              redirect_to :back
              return
            end
          end
          if @file.locked? && !@file.locks.empty?
            begin
              @file.unlock!
              flash[:notice] = "#{l(:notice_file_unlocked)}, "
            rescue => e
              Rails.logger.error "Cannot unlock the file: #{e.message}"
            end
          end
          if @file.save
            @file.set_last_revision revision
            Redmine::Hook.call_hook :dmsf_helper_upload_after_commit, { file: @file }
            flash[:notice] = (flash[:notice].nil? ? '' : flash[:notice]) + l(:notice_file_revision_created)
            begin
              recipients = DmsfMailer.deliver_files_updated(@project, [@file])
              if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
                if recipients.any?
                  to = recipients.collect{ |r| h(r.name) }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                  to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                  flash[:warning] = l(:warning_email_notifications, to: to)
                end
              end
            rescue => e
              Rails.logger.error "Could not send email notifications: #{e.message}"
            end
          else
            flash[:error] = @file.errors.full_messages.to_sentence
          end
        else
          flash[:error] = revision.errors.full_messages.to_sentence
        end
      end
    end
    redirect_to :back
  end

  def delete
    if @file
      commit = params[:commit] == 'yes'
      result = @file.delete(commit)
      if result
        flash[:notice] = l(:notice_file_deleted)
        unless commit
          begin
            recipients = DmsfMailer.deliver_files_deleted(@project, [@file])
            if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
              if recipients.any?
                to = recipients.collect{ |r| h(r.name) }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                flash[:warning] = l(:warning_email_notifications, to: to)
              end
            end
          rescue => e
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
      format.html do
        redirect_to dmsf_folder_path(id: @project, folder_id: @folder)
      end
      format.api { result ? render_api_ok : render_validation_errors(@file) }
    end
  end

  def delete_revision
    if @revision
      if @revision.delete(true)
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
      rescue => e
        flash[:error] = e.message
      end
    end
    redirect_to :back
  end

  def unlock
    unless @file.locked?
      flash[:warning] = l(:warning_file_not_locked)
    else
      if @file.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @file.project)
        begin
          @file.unlock!
          flash[:notice] = l(:notice_file_unlocked)
        rescue => e
          flash[:error] = e.message
        end
      else
        flash[:error] = l(:error_only_user_that_locked_file_can_unlock_it)
      end
    end
    redirect_to :back
  end

  def notify_activate
    if @file.notification
      flash[:warning] = l(:warning_file_notifications_already_activated)
    else
      @file.notify_activate
      flash[:notice] = l(:notice_file_notifications_activated)
    end
    redirect_to :back
  end

  def notify_deactivate
    unless @file.notification
      flash[:warning] = l(:warning_file_notifications_already_deactivated)
    else
      @file.notify_deactivate
      flash[:notice] = l(:notice_file_notifications_deactivated)
    end
    redirect_to :back
  end

  def restore
    if @file.restore
      flash[:notice] = l(:notice_dmsf_file_restored)
    else
      flash[:error] = @file.errors.full_messages.to_sentence
    end
    redirect_to :back
  end

  def thumbnail
    if @file.image? && tbnail = @file.thumbnail(:size => params[:size])
      if stale?(:etag => tbnail)
        send_file tbnail,
                  filename: filename_for_content_disposition(@file.last_revision.disk_file),
                  type: @file.last_revision.detect_content_type,
                  disposition: 'inline'
      end
    else
      head 404
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
    if entry && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project)
    end
  end

end