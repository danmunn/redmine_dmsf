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

class DmsfDetailController < ApplicationController
  unloadable
  
  menu_item :dmsf
  
  before_filter :find_project
  before_filter :authorize
  before_filter :find_parent, :only => [:folder_new, :create_folder, :save_folder]
  before_filter :find_folder, :only => [:delete_folder, :save_folder,
    :upload_files, :commit_files, :folder_detail]
  before_filter :find_file, :only => [:save_file, :delete_file, :file_detail]

  def folder_new
    @pathfolder = @parent
    render :action => "folder_detail"
  end

  def create_folder
    @folder = DmsfFolder.new(params[:dmsf_folder])
    @folder.project = @project
    @folder.folder = @parent
    @folder.user = User.current
    if @folder.save
      flash[:notice] = l(:notice_folder_created)
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} created folder #{@project.identifier}://#{@folder.dmsf_path_str}"
      redirect_to({:controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder})
    else
      @pathfolder = @parent
      render :action => "folder_detail"
    end
  end

  def folder_detail
    @parent = @folder.folder
    @pathfolder = copy_folder(@folder)
  end

  def save_folder
    unless params[:dmsf_folder]
      redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
      return
    end
    @pathfolder = copy_folder(@folder)
    @folder.attributes = params[:dmsf_folder]
    if @folder.save
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} updated folder #{@project.identifier}://#{@folder.dmsf_path_str}"
      flash[:notice] = l(:notice_folder_details_were_saved)
      redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
    else
      render :action => "folder_detail"
    end
  end

  def delete_folder
    check_project(@delete_folder = DmsfFolder.find(params[:delete_folder_id]))
    if !@delete_folder.nil?
      if @delete_folder.subfolders.empty? && @delete_folder.files.empty?
        @delete_folder.destroy
        flash[:notice] = l(:notice_folder_deleted)
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted folder #{@project.identifier}://#{@delete_folder.dmsf_path_str}"
      else
        flash[:error] = l(:error_folder_is_not_empty)
      end
    end
    
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
  rescue DmsfAccessError
    render_403  
  end

  def file_detail
    @revision = @file.last_revision
  end

  #TODO: don't create revision if nothing change
  def save_file
    unless params[:dmsf_file_revision]
      redirect_to :action => "file_detail", :id => @project, :file_id => @file
      return
    end
    if @file.locked_for_user?
      flash[:error] = l(:error_file_is_locked)
      redirect_to :action => "file_detail", :id => @project, :file_id => @file
    else
      #TODO: validate folder_id
      @revision = DmsfFileRevision.new(params[:dmsf_file_revision])
      
      @revision.file = @file
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
      
      if @revision.save && @file.valid?
        unless file_upload.nil?
          @revision.copy_file_content(file_upload)
        end
        
        if @file.locked?
          DmsfFileLock.file_lock_state(@file, false)
          flash[:notice] = l(:notice_file_unlocked) + ", "
        end
        @file.save!
        @file.reload
        
        flash[:notice] = (flash[:notice].nil? ? "" : flash[:notice]) + l(:notice_file_revision_created)
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} created new revision of file #{@project.identifier}://#{@file.dmsf_path_str}"
        begin
          DmsfMailer.deliver_files_updated(User.current, [@file])
        rescue ActionView::MissingTemplate => e
          Rails.logger.error "Could not send email notifications: " + e
        end
        redirect_to :action => "file_detail", :id => @project, :file_id => @file
      else
        render :action => "file_detail"
      end
    end
  end

  def delete_file
    if !@file.nil?
      if @file.locked_for_user?
        flash[:error] = l(:error_file_is_locked)
      else
        @file.deleted = true
        @file.deleted_by_user = User.current
        @file.save
        flash[:notice] = l(:notice_file_deleted)
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted file #{@project.identifier}://#{@file.dmsf_path_str}"
        DmsfMailer.deliver_files_deleted(User.current, [@file])
      end
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @file.folder
  end

  def delete_revision
    @revision = DmsfFileRevision.find(params[:revision_id])
    check_project(@revision.file)
    if @revision.file.locked_for_user?
      flash[:error] = l(:error_file_is_locked)
    else
      if !@revision.nil? && !@revision.deleted
        if @revision.file.revisions.size <= 1
          flash[:error] = l(:error_at_least_one_revision_must_be_present)
        else
          @revision.deleted = true
          @revision.deleted_by_user = User.current
          @revision.save
          flash[:notice] = l(:notice_revision_deleted)
          Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted revision #{@project.identifier}://#{@revision.file.dmsf_path_str}/#{@revision.id}"
        end
      end
    end
    redirect_to :action => "file_detail", :id => @project, :file_id => @revision.file
  end

  def upload_files
    uploaded_files = params[:uploaded_files]
    @uploads = []
    if uploaded_files && uploaded_files.is_a?(Hash)
      # standard file input uploads
      uploaded_files.each_value do |uploaded_file|
        @uploads.push(DmsfUpload.create_from_uploaded_file(@project, @folder, uploaded_file))
      end
    else
      # plupload multi upload completed
      uploaded = params[:uploaded]
      if uploaded && uploaded.is_a?(Hash)
        uploaded.each_value do |uploaded_file|
          @uploads.push(DmsfUpload.new(@project, @folder, uploaded_file))
        end
      end
    end
  end

  # plupload single file multi upload handling 
  def upload_file
    @tempfile = params[:file]
    @disk_filename = DmsfHelper.temp_filename(@tempfile.original_filename)
    File.open("#{DmsfHelper.temp_dir}/#{@disk_filename}", "wb") do |f| 
      while (buffer = @tempfile.read(8192))
        f.write(buffer)
      end
    end
    
    render :layout => false
  end

  #TODO: flash notice when files saved and unlocked
  #TODO: separate control for approval
  def commit_files
    commited_files = params[:commited_files]
    if commited_files && commited_files.is_a?(Hash)
      files = []
      failed_uploads = []
      commited_files.each_value do |commited_file|
        name = commited_file["name"];
        
        new_revision = DmsfFileRevision.new
        file = DmsfFile.find_file_by_name(@project, @folder, name)
        if file.nil?
          file = DmsfFile.new
          file.project = @project
          file.name = name
          file.folder = @folder
          file.notification = !Setting.plugin_redmine_dmsf["dmsf_default_notifications"].blank?
          
          new_revision.minor_version = 0
          new_revision.major_version = 0
        else
          if file.locked_for_user?
            failed_uploads.push(commited_file)
            next
          end
          last_revision = file.last_revision
          new_revision.source_revision = last_revision
          new_revision.major_version = last_revision.major_version
          new_revision.minor_version = last_revision.minor_version
          new_revision.workflow = last_revision.workflow
        end
        
        commited_disk_filepath = "#{DmsfHelper.temp_dir}/#{commited_file["disk_filename"]}"
        
        new_revision.folder = @folder
        new_revision.file = file
        new_revision.user = User.current
        new_revision.name = name
        new_revision.title = commited_file["title"]
        new_revision.description = commited_file["description"]
        new_revision.comment = commited_file["comment"]
        new_revision.increase_version(commited_file["version"].to_i, true)
        new_revision.set_workflow(commited_file["workflow"])
        new_revision.mime_type = Redmine::MimeType.of(new_revision.name)
        new_revision.size = File.size(commited_disk_filepath)
        new_revision.disk_filename = new_revision.new_storage_filename

        file_upload = File.new(commited_disk_filepath, "rb")
        if file_upload.nil?
          failed_uploads.push(commited_file)
          flash[:error] = l(:error_file_commit_require_uploaded_file)
          next
        end
        
        if new_revision.save
          if file.locked?
            DmsfFileLock.file_lock_state(file, false)
            flash[:notice] = l(:notice_file_unlocked)
          end
          file.save!
          file.reload
          
          # Need to save file first to generate id for it in case of creation. 
          # File id is needed to properly generate revision disk filename
          new_revision.copy_file_content(file_upload)
          file_upload.close
          File.delete(commited_disk_filepath)
          
          files.push(file)
        else
          failed_uploads.push(commited_file)
        end
      end
      unless files.empty?
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} uploaded for project #{@project.identifier}:"
        files.each {|file| Rails.logger.info "\t#{file.dmsf_path_str}:"}
        begin 
          DmsfMailer.deliver_files_updated(User.current, files)
        rescue ActionView::MissingTemplate => e
          Rails.logger.error "Could not send email notifications: " + e
        end
      end
      unless failed_uploads.empty?
        flash[:warning] = l(:warning_some_files_were_not_commited, :files => failed_uploads.map{|u| u["name"]}.join(", "))
      end
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
  end

  private
  
  def copy_folder(folder)
    copy = folder.clone
    copy.id = folder.id
    copy
  end
  
  def find_project
    @project = Project.find(params[:id])
  end
  
  def find_folder
    @folder = DmsfFolder.find(params[:folder_id]) if params.keys.include?("folder_id")
    check_project(@folder)
  rescue DmsfAccessError
    render_403
  end

  def find_parent
    @parent = DmsfFolder.find(params[:parent_id]) if params.keys.include?("parent_id")
    check_project(@parent)
  rescue DmsfAccessError
    render_403
  end

  def find_file
    check_project(@file = DmsfFile.find(params[:file_id]))
  rescue DmsfAccessError
    render_403
  end

  def check_project(entry)
    if !entry.nil? && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end
  end
  
end