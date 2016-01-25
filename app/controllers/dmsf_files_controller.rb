# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
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

  before_filter :find_file, :except => [:delete_revision]
  before_filter :find_revision, :only => [:delete_revision]
  before_filter :authorize  

  accept_api_auth :show

  helper :all
  helper :dmsf_workflows

  def view
    begin
      if params[:download].blank?
        @revision = @file.last_revision
      else
        @revision = DmsfFileRevision.find(params[:download].to_i)
        raise DmsfAccessError if @revision.file != @file
      end
      check_project(@revision.file)    
      raise ActionController::MissingFile if @file.deleted
      log_activity('downloaded')      
      access = DmsfFileRevisionAccess.new
      access.user = User.current
      access.revision = @revision
      access.action = DmsfFileRevisionAccess::DownloadAction      
      access.save!
      member = Member.where(:user_id => User.current.id, :project_id => @file.project.id).first
      send_file(@revision.disk_file,        
        :filename => filename_for_content_disposition(@revision.formatted_name(member ? member.title_format : nil)),
        :type => @revision.detect_content_type,
        :disposition => 'inline')    
    rescue DmsfAccessError => e
      Rails.logger.error e.message
      render_403
    rescue Exception => e
      Rails.logger.error e.message
      render_404
    end
  end

  def show
    # The download is put here to provide more clear and usable links
    if params.has_key?(:download)
      begin
        if params[:download].blank?
          @revision = @file.last_revision
        else
          @revision = DmsfFileRevision.find(params[:download].to_i)
          raise DmsfAccessError if @revision.file != @file
        end
        check_project(@revision.file)      
        raise ActionController::MissingFile if @revision.file.deleted
        log_activity('downloaded')        
        access = DmsfFileRevisionAccess.new
        access.user = User.current
        access.revision = @revision
        access.action = DmsfFileRevisionAccess::DownloadAction
        access.save!
        member = Member.where(:user_id => User.current.id, :project_id => @file.project.id).first
        send_file(@revision.disk_file,          
          :filename => filename_for_content_disposition(@revision.formatted_name(member ? member.title_format : nil)),
          :type => @revision.detect_content_type,
          :disposition => 'attachment')
      rescue DmsfAccessError => e
        Rails.logger.error e.message
        render_403
      rescue Exception => e
        Rails.logger.error e.message
        render_404
      end
      return
    end

    @revision = @file.last_revision
    @file_delete_allowed = User.current.allowed_to?(:file_delete, @project)
    @revision_pages = Paginator.new @file.revisions.visible.count, params['per_page'] ? params['per_page'].to_i : 25, params['page']

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

        revision.file = @file
        last_revision = @file.last_revision
        revision.source_revision = last_revision
        revision.user = User.current

        revision.major_version = last_revision.major_version
        revision.minor_version = last_revision.minor_version
        version = params[:version].to_i
        file_upload = params[:file_upload]
        unless file_upload
          revision.disk_filename = last_revision.disk_filename
          if version == 3
           revision.major_version = params[:custom_version_major].to_i
           revision.minor_version = params[:custom_version_minor].to_i
          else
            revision.increase_version(version, false)
          end
          revision.mime_type = last_revision.mime_type
          revision.size = last_revision.size
        else
          if version == 3
           revision.major_version = params[:custom_version_major].to_i
           revision.minor_version = params[:custom_version_minor].to_i
          else
            revision.increase_version(version, true)
          end
          revision.size = file_upload.size
          revision.disk_filename = revision.new_storage_filename
          revision.mime_type = Redmine::MimeType.of(file_upload.original_filename)
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
          if file_upload
            revision.copy_file_content(file_upload)
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
              if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
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
            DmsfMailer.get_notify_users(@project, [@file]).each do |u|
              DmsfMailer.files_deleted(u, @project, [@file]).deliver
            end
          rescue Exception => e
            Rails.logger.error "Could not send email notifications: #{e.message}"
          end
        end
      else
        @file.errors.each do |e, msg|
          flash[:error] = msg
        end
      end
    end
    if commit
      redirect_to :back
    else
      redirect_to dmsf_folder_path(:id => @project, :folder_id => @file.folder)
    end
  end

  def delete_revision
    if @revision # && !@revision.deleted
      if @revision.delete(true)
        flash[:notice] = l(:notice_revision_deleted)
        log_activity('deleted')
      else
        @revision.errors.each do |e, msg|
          flash[:error] = msg
        end
      end
    end
    redirect_to :action => 'show', :id => @file
  end

  def lock
    if @file.locked?
      flash[:warning] = l(:warning_file_already_locked)
    else
      @file.lock!
      flash[:notice] = l(:notice_file_locked)
    end
    redirect_to :back
  end

  def unlock
    unless @file.locked?
      flash[:warning] = l(:warning_file_not_locked)
    else
      if @file.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @file.project)
        @file.unlock!
        flash[:notice] = l(:notice_file_unlocked)
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

  private

  def frev_params
    params.require(:dmsf_file_revision).permit(
      :title, :name, :description, :comment)
  end

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
    @file = @revision.file
    @project = @file.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def check_project(entry)
    if entry && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project)
    end
  end

end
