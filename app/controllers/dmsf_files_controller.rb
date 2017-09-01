# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
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

class DmsfFilesController < ApplicationController
  unloadable

  menu_item :dmsf

  before_action :find_file, :except => [:delete_revision]
  before_action :find_revision, :only => [:delete_revision]
  before_action :authorize
  before_action :tree_view, :only => [:delete]
  before_action :permissions

  accept_api_auth :show

  helper :all
  helper :dmsf_workflows
  helper :dmsf

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
      check_project(@revision.dmsf_file)
      raise ActionController::MissingFile if @file.deleted?
      log_activity('downloaded')
      access = DmsfFileRevisionAccess.new
      access.user = User.current
      access.dmsf_file_revision = @revision
      access.action = DmsfFileRevisionAccess::DownloadAction
      access.save!
      member = Member.where(:user_id => User.current.id, :project_id => @file.project.id).first
      if member && !member.title_format.nil? && !member.title_format.empty?
        title_format = member.title_format
      else
        title_format = Setting.plugin_redmine_dmsf['dmsf_global_title_format']
      end
      # IE has got a tendency to cache files
      expires_in(0.year, "must-revalidate" => true)
      send_file(@revision.disk_file,
        :filename => filename_for_content_disposition(@revision.formatted_name(title_format)),
        :type => @revision.detect_content_type,
        :disposition => @revision.dmsf_file.disposition)
    rescue DmsfAccessError => e
      Rails.logger.error e.message
      render_403
    rescue Exception => e
      Rails.logger.error e.message
      render_404
    end
  end

  def show
    @revision = @file.last_revision
    @file_delete_allowed = User.current.allowed_to?(:file_delete, @project)
    @file_manipulation_allowed = User.current.allowed_to?(:file_manipulation, @project)
    @revision_pages = Paginator.new @file.dmsf_file_revisions.visible.count, params['per_page'] ? params['per_page'].to_i : 25, params['page']

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
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
          revision.major_version = params[:custom_version_major].to_i
          revision.minor_version = params[:custom_version_minor].to_i
        else
           revision.increase_version(version)
        end
        file_upload = params[:dmsf_attachments]['1'] if params[:dmsf_attachments].present?
        unless file_upload
          revision.size = last_revision.size
          revision.disk_filename = last_revision.disk_filename
          revision.mime_type = last_revision.mime_type
          if last_revision.digest.blank?
            revision.digest = DmsfFileRevision.create_digest last_revision.disk_file
          else
            revision.digest = last_revision.digest
          end
        else
          upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, file_upload)
          if upload
            revision.size = upload.size
            revision.disk_filename = revision.new_storage_filename
            revision.mime_type = upload.mime_type
            revision.digest = DmsfFileRevision.create_digest upload.tempfile_path
          end
        end

        # Custom fields
        if params[:dmsf_file_revision][:custom_field_values].present?
          params[:dmsf_file_revision][:custom_field_values].each_with_index do |v, i|
            revision.custom_field_values[i].value = v[1]
          end
        end

        @file.name = revision.name

        if revision.save
          revision.assign_workflow(params[:dmsf_workflow_id])
          if upload
            FileUtils.mv(upload.tempfile_path, revision.disk_file(false))
          end
          if @file.locked? && !@file.locks.empty?
            begin
              @file.unlock!
              flash[:notice] = "#{l(:notice_file_unlocked)}, "
            rescue Exception => e
              logger.error "Cannot unlock the file: #{e.message}"
            end
          end
          if @file.save
            @file.set_last_revision revision
            flash[:notice] = (flash[:notice].nil? ? '' : flash[:notice]) + l(:notice_file_revision_created)
            log_activity('new revision')
            begin
              recipients = DmsfMailer.get_notify_users(@project, [@file])
              recipients.each do |u|
                DmsfMailer.files_updated(u, @project, [@file]).deliver
              end
              if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] == '1'
                unless recipients.empty?
                  to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                  to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                  flash[:warning] = l(:warning_email_notifications, :to => to)
                end
              end
            rescue Exception => e
              logger.error "Could not send email notifications: #{e.message}"
            end
          else
            flash[:error] = @file.errors.full_messages.join(', ')
          end
        else
          flash[:error] = revision.errors.full_messages.join(', ')
        end
      end
    end
    redirect_to :back
  end

  def delete
    if @file
      commit = params[:commit] == 'yes'
      if @file.delete(commit)
        flash[:notice] = l(:notice_file_deleted)
        if commit
          log_activity('deleted')
          begin
            recipients = DmsfMailer.get_notify_users(@project, [@file])
            recipients.each do |u|
              DmsfMailer.files_deleted(u, @project, [@file]).deliver
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
      else
        flash[:error] = @file.errors.full_messages.join(', ')
      end
    end
    if commit || (@tree_view && params[:details].blank?)
      redirect_to :back
    else
      redirect_to dmsf_folder_path(:id => @project, :folder_id => @file.dmsf_folder)
    end
  end

  def delete_revision
    if @revision
      if @revision.delete(true)
        if @file.name != @file.last_revision.name
          @file.name = @file.last_revision.name
          @file.save
        end
        flash[:notice] = l(:notice_revision_deleted)
        log_activity('deleted')
      else
        flash[:error] = @revision.errors.full_messages.join(', ')
      end
    end
    redirect_to :action => 'show', :id => @file
  end

  def lock
    if @file.locked?
      flash[:warning] = l(:warning_file_already_locked)
    else
      begin
        @file.lock!
        flash[:notice] = l(:notice_file_locked)
      rescue Exception => e
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
        rescue Exception => e
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
      log_activity('restored')
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
                  :filename => filename_for_content_disposition(@file.last_revision.disk_file),
                  :type => @file.last_revision.detect_content_type,
                  :disposition => 'inline'
      end
    else
      head 404
    end
  end

  private

  def log_activity(action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{@file.project.identifier}/#{@file.id}/#{@revision.id if @revision}"
  end

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

  def check_project(entry)
    if entry && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project)
    end
  end

  def tree_view
    tag = params[:custom_field_id].present? && params[:custom_value].present?
    @tree_view = (User.current.pref[:dmsf_tree_view] == '1') && (!%w(atom xml json).include?(params[:format])) && !tag
  end

end