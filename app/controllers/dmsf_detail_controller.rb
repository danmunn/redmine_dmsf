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
  
  before_filter :find_project
  before_filter :authorize
  before_filter :find_folder, :only => [:create_folder, :delete_folder, :save_folder,
    :upload_files, :commit_files, :folder_detail]
  before_filter :find_file, :only => [:save_file, :delete_file, :file_detail]
  
  def create_folder
    @new_folder = DmsfFolder.create_from_params(@project, @folder, params[:dmsf_folder])
    if @new_folder.valid?
      flash[:notice] = "Folder created"
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} created folder #{@project.identifier}://#{@new_folder.dmsf_path_str}"
    else
      flash[:error] = "Folder creation failed: Title must be entered"
    end

    redirect_to({:controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder})
  end
  
  def delete_folder
    check_project(@delete_folder = DmsfFolder.find(params[:delete_folder_id]))
    if !@delete_folder.nil?
      if @delete_folder.subfolders.empty? && @delete_folder.files.empty?
        @delete_folder.destroy
        flash[:notice] = "Folder deleted"
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted folder #{@project.identifier}://#{@delete_folder.dmsf_path_str}"
      else
        flash[:error] = "Folder is not empty"
      end
    end
    
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
  rescue DmsfAccessError
    render_403  
  end

  def folder_detail
  end

  def save_folder
    @folder.description = params[:description]
    
    if params[:title].blank?
      flash.now[:error] = "Title must be entered"
      render "folder_detail"
      return
    end
    
    @folder.name = params[:title]
    
    if !@folder.valid?
      flash.now[:error] = "Title is already used"
      render "folder_detail"
      return
    end

    @folder.save!
    Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} updated folder #{@project.identifier}://#{@folder.dmsf_path_str}"
    flash[:notice] = "Folder details were saved"
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
  end

  #TODO: show lock/unlock history
  def file_detail
  end

  def delete_file
    if !@file.nil?
      if @file.locked_for_user?
        flash[:error] = "File is locked"
      else
        @file.deleted = true
        @file.deleted_by_user = User.current
        @file.save
        flash[:notice] = "File deleted"
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
      flash[:error] = "File is locked"
    else
      if !@revision.nil? && !@revision.deleted
        if @revision.file.revisions.size <= 1
          flash[:error] = "At least one revision must be present"
        else
          @revision.deleted = true
          @revision.deleted_by_user = User.current
          @revision.save
          flash[:notice] = "Revision deleted"
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
      commited_files.each_value do |commited_file|
        file = DmsfFile.from_commited_file(@project, @folder, commited_file)
        if file.locked_for_user?
          flash[:error] = "One of files locked"
        else
          revision = DmsfFileRevision.from_commited_file(file, commited_file)
          file.unlock if file.locked?
          file.reload
          files.push(file)
        end
      end
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} uploaded for project #{@project.identifier}:"
      files.each {|file| Rails.logger.info "\t#{file.dmsf_path_str}:"}
      begin 
        DmsfMailer.deliver_files_updated(User.current, files)
      rescue ActionView::MissingTemplate => e
        Rails.logger.error "Could not send email notifications: " + e
      end
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
  end

  #TODO: separate control for approval
  #TODO: don't create revision if nothing change
  def save_file
    if @file.locked_for_user?
      flash[:error] = "File locked"
    else
      saved_file = params[:file]
      DmsfFileRevision.from_saved_file(@file, saved_file)
      if @file.locked?
        @file.unlock
        flash[:notice] = "File unlocked, "
      end
      @file.reload
      flash[:notice] = (flash[:notice].nil? ? "" : flash[:notice]) + "File revision created"
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} created new revision of file #{@project.identifier}://#{@file.dmsf_path_str}"
      begin
        DmsfMailer.deliver_files_updated(User.current, [@file])
      rescue ActionView::MissingTemplate => e
        Rails.logger.error "Could not send email notifications: " + e
      end
    end
    redirect_to :action => "file_detail", :id => @project, :file_id => @file
  end

  private
  
  def find_project
    @project = Project.find(params[:id])
  end
  
  def find_folder
    @folder = DmsfFolder.find(params[:folder_id]) if params.keys.include?("folder_id")
    check_project(@folder)
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
      raise DmsfAccessError, "Entry project doesn't match current project" 
    end
  end
  
end