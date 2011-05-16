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
    @revision = @file.last_revision.clone
  end

  #TODO: separate control for approval
  #TODO: don't create revision if nothing change
  def save_file
    if @file.locked_for_user?
      flash[:error] = l(:error_file_is_locked)
      redirect_to :action => "file_detail", :id => @project, :file_id => @file
    else
      new_revision = params[:dmsf_file_revision]
      DmsfFileRevision.from_saved_file(@file, new_revision)
      if @file.locked?
        @file.unlock
        flash[:notice] = l(:notice_file_unlocked) + ", "
      end
      @file.reload
      flash[:notice] = (flash[:notice].nil? ? "" : flash[:notice]) + l(:notice_file_revision_created)
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} created new revision of file #{@project.identifier}://#{@file.dmsf_path_str}"
      begin
        DmsfMailer.deliver_files_updated(User.current, [@file])
      rescue ActionView::MissingTemplate => e
        Rails.logger.error "Could not send email notifications: " + e
      end
    end
    redirect_to :action => "file_detail", :id => @project, :file_id => @file
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
      commited_files.each_value do |commited_file|
        file = DmsfFile.from_commited_file(@project, @folder, commited_file)
        if file.locked_for_user?
          flash[:warning] = l(:warning_one_of_files_locked)
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
        DmsfMailer.deliver_files_updated(User.current, files) unless files.empty?
      rescue ActionView::MissingTemplate => e
        Rails.logger.error "Could not send email notifications: " + e
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