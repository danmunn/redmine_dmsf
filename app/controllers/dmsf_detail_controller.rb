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
  before_filter :authorize, :except => [:delete_entries]
  before_filter :find_parent, :only => [:folder_new, :create_folder, :save_folder]
  before_filter :find_folder, :only => [:delete_folder, :save_folder, :folder_detail, :delete_entries]
  before_filter :find_file, :only => [:save_file, :delete_file, :file_detail]

  def delete_entries
    selected_folders = params[:subfolders]
    selected_files = params[:files]
    if selected_folders.nil? && selected_files.nil?
      flash[:warning] = l(:warning_no_entries_selected)
    else
      failed_entries = []
      deleted_files = []
      deleted_folders = []
      unless selected_folders.nil?
        if User.current.allowed_to?(:folder_manipulation, @project)
          selected_folders.each do |subfolderid|
            subfolder = DmsfFolder.find(subfolderid)
            next if subfolder.nil?
            if subfolder.project != @project || !subfolder.delete
              failed_entries.push(subfolder) 
            else
              deleted_folders.push(subfolder)
            end
          end
        else
          flash[:error] = l(:error_user_has_not_right_delete_folder)
        end
      end
      unless selected_files.nil?
        if User.current.allowed_to?(:file_manipulation, @project)
          selected_files.each do |fileid|
            file = DmsfFile.find(fileid)
            next if file.nil?
            if file.project != @project || !file.delete
              failed_entries.push(file)
            else
              deleted_files.push(file)
            end
          end
        else
          flash[:error] = l(:error_user_has_not_right_delete_file)
        end
      end
      unless deleted_folders.empty?
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted folders from project #{@project.identifier}:"
        deleted_folders.each {|f| Rails.logger.info "\t#{f.dmsf_path_str}:"}
      end
      unless deleted_files.empty?
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted files from project #{@project.identifier}:"
        deleted_files.each {|f| Rails.logger.info "\t#{f.dmsf_path_str}:"}
        DmsfMailer.deliver_files_deleted(User.current, deleted_files)
      end
      if failed_entries.empty?
        flash[:notice] = l(:notice_entries_deleted)
      else
        flash[:warning] = l(:warning_some_entries_were_not_deleted, :entries => failed_entries.map{|e| e.title}.join(", "))
      end
    end
    
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder
  end

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
      if @delete_folder.delete
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
    # TODO: line bellow is to handle old instalations with errors in data handling
    @revision.name = @file.name
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
      
      if @revision.valid? && @file.valid?
        @revision.save!
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
      if @file.delete
        flash[:notice] = l(:notice_file_deleted)
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted file #{@project.identifier}://#{@file.dmsf_path_str}"
        DmsfMailer.deliver_files_deleted(User.current, [@file])
      else
        flash[:error] = l(:error_file_is_locked)
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