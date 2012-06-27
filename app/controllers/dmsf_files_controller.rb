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

class DmsfFilesController < ApplicationController
  unloadable
  
  menu_item :dmsf
  
  before_filter :find_file, :except => [:delete_revision]
  before_filter :find_revision, :only => [:delete_revision]
  before_filter :authorize

  helper :all

  def show
    # download is put here to provide more clear and usable links
    if params.has_key?(:download)
      if @file.deleted
        render_404
        return
      end
      if params[:download].blank?
        @revision = @file.last_revision
      else
        @revision = DmsfFileRevision.visible.find(params[:download].to_i)
        if @revision.file != @file
          render_403
          return
        end
        if @revision.deleted
          render_404
          return
        end
      end
      check_project(@revision.file)
      send_revision
      return
    end
    
    @revision = @file.last_revision
    # TODO: line bellow is to handle old instalations with errors in data handling
    @revision.name = @file.name
    
    @revision_pages = Paginator.new self, @file.revisions.visible.count, params["per_page"] ? params["per_page"].to_i : 25, params["page"]
    
    render :layout => !request.xhr?
  end

  #TODO: don't create revision if nothing change
  def create_revision
    unless params[:dmsf_file_revision]
      redirect_to :action => "show", :id => @file
      return
    end
    if @file.locked_for_user?
      flash[:error] = l(:error_file_is_locked)
      redirect_to :action => "show", :id => @file
    else
      #TODO: validate folder_id
      @revision = DmsfFileRevision.new(params[:dmsf_file_revision])
      
      @revision.file = @file
      @revision.project = @file.project
      last_revision = @file.last_revision
      @revision.source_revision = last_revision
      @revision.user = User.current
      
      @revision.major_version = last_revision.major_version
      @revision.minor_version = last_revision.minor_version
      @revision.workflow = last_revision.workflow
      version = params[:version].to_i
      file_upload = params[:file_upload]
      if file_upload.nil?
        @revision.disk_filename = last_revision.disk_filename
        @revision.increase_version(version, false)
        @revision.mime_type = last_revision.mime_type
        @revision.size = last_revision.size
      else
        @revision.increase_version(version, true)
        @revision.size = file_upload.size
        @revision.disk_filename = @revision.new_storage_filename
        @revision.mime_type = Redmine::MimeType.of(file_upload.original_filename)
      end
      @revision.set_workflow(params[:workflow])
      
      @file.name = @revision.name
      @file.folder = @revision.folder
      
      if @revision.valid? && @file.valid?
        @revision.save!
        unless file_upload.nil?
          @revision.copy_file_content(file_upload)
        end
        
        if @file.locked? && !@file.locks.empty?
          begin
            @file.unlock!
            flash[:notice] = l(:notice_file_unlocked) + ", "
          rescue
            #Nothing to do here
          end
        end
        @file.save!
        @file.reload
        
        flash[:notice] = (flash[:notice].nil? ? "" : flash[:notice]) + l(:notice_file_revision_created)
        log_activity("new revision")
        begin
          DmsfMailer.files_updated(User.current, [@file]).deliver
        rescue ActionView::MissingTemplate => e
          Rails.logger.error "Could not send email notifications: " + e
        end
        redirect_to :action => "show", :id => @file
      else
        render :action => "show"
      end
    end
  end

  def delete
    if !@file.nil?
      if @file.delete
        flash[:notice] = l(:notice_file_deleted)
        log_activity("deleted")
        DmsfMailer.files_deleted(User.current, [@file]).deliver
      else
        flash[:error] = l(:error_file_is_locked)
      end
    end
    redirect_to :controller => "dmsf", :action => "show", :id => @project, :folder_id => @file.folder
  end

  def delete_revision
    if !@revision.nil? && !@revision.deleted
      if @revision.delete
        flash[:notice] = l(:notice_revision_deleted)
        log_activity("deleted")
      else
        # TODO: check this error handling
        @revision.errors.each {|e,msg| flash[:error] = msg}
      end
    end
    redirect_to :action => "show", :id => @file
  end

  def lock
    if @file.locked?
      flash[:warning] = l(:warning_file_already_locked)
    else
      @file.lock!
      flash[:notice] = l(:notice_file_locked)
    end
      redirect_to params[:current] ? params[:current] : 
        {:controller => "dmsf", :action => "show", :id => @project, :folder_id => @file.folder}
  end
  
  def unlock
    if !@file.locked?
      flash[:warning] = l(:warning_file_not_locked)
    else
      if @file.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @file.project)
        @file.unlock!
        flash[:notice] = l(:notice_file_unlocked)
      else
        flash[:error] = l(:error_only_user_that_locked_file_can_unlock_it)
      end
    end
    redirect_to params[:current] ? params[:current] : 
        {:controller => "dmsf", :action => "show", :id => @project, :folder_id => @file.folder}
  end

  def notify_activate
    if @file.notification
      flash[:warning] = l(:warning_file_notifications_already_activated)
    else
      @file.notify_activate
      flash[:notice] = l(:notice_file_notifications_activated)
    end
    redirect_to params[:current] ? params[:current] :
      {:controller => "dmsf", :action => "show", :id => @project, :folder_id => @file.folder}
  end
  
  def notify_deactivate
    if !@file.notification
      flash[:warning] = l(:warning_file_notifications_already_deactivated)
    else
      @file.notify_deactivate
      flash[:notice] = l(:notice_file_notifications_deactivated)
    end
    redirect_to params[:current] ? params[:current] :
      {:controller => "dmsf", :action => "show", :id => @project, :folder_id => @file.folder}
  end

  private

  def log_activity(action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{@file.project.identifier}/#{@file.id}/#{@revision.id if @revision}"
  end

  def send_revision
    log_activity("downloaded")
    access = DmsfFileRevisionAccess.new(:user_id => User.current.id, :dmsf_file_revision_id => @revision.id, 
      :action => DmsfFileRevisionAccess::DownloadAction)
    access.save!
    send_file(@revision.disk_file, 
      :filename => filename_for_content_disposition(@revision.name),
      :type => @revision.detect_content_type, 
      :disposition => "attachment")
  end
  
  def find_file
    @file = DmsfFile.visible.find(params[:id])
    @project = @file.project
  rescue
  end

  def find_revision
    @revision = DmsfFileRevision.visible.find(params[:id])
    @file = @revision.file 
    @project = @file.project
  end

  def check_project(entry)
    if !entry.nil? && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end
  end
  
end
