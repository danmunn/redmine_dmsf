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

class DmsfController < ApplicationController
  unloadable
  
  before_filter :find_project
  before_filter :authorize, :except => [:delete_entries]
  before_filter :find_folder, :except => [:new, :create, :edit_root, :save_root]
  before_filter :find_parent, :only => [:new, :create]
  
  helper :sort
  include SortHelper
  
  def show
    sort_init ["title", "asc"]
    sort_update ["title", "size", "modified", "version", "author"]
    
    if @folder.nil?
      @subfolders = DmsfFolder.project_root_folders(@project)
      @files = DmsfFile.project_root_files(@project)
    else 
      @subfolders = @folder.subfolders
      @files = @folder.files
    end
    
    @files.sort! do |a,b|
      case @sort_criteria.first_key
        when "size" then a.last_revision.size <=> b.last_revision.size
        when "modified" then a.last_revision.updated_at <=> b.last_revision.updated_at
        when "version" then
          result = a.last_revision.major_version <=> b.last_revision.major_version
          result == 0 ? a.last_revision.minor_version <=> b.last_revision.minor_version : result
        when "author" then a.last_revision.user <=> b.last_revision.user
        else a.last_revision.title <=> b.last_revision.title
      end
    end
    
    if !@sort_criteria.first_asc?
      @subfolders.reverse!  
      @files.reverse!
    end
    
    render :layout => !request.xhr?
    
  end

  def entries_operation
    selected_folders = params[:subfolders]
    selected_files = params[:files]
    
    if selected_folders.nil? && selected_files.nil?
      flash[:warning] = l(:warning_no_entries_selected)
      redirect_to :action => "show", :id => @project, :folder_id => @folder
      return
    end
    
    if !params[:email_entries].blank?
      email_entries(selected_folders, selected_files)
    else
      download_entries(selected_folders, selected_files)
    end
  rescue ZipMaxFilesError
    flash[:error] = l(:error_max_files_exceeded, :number => Setting.plugin_redmine_dmsf["dmsf_max_file_download"].to_i.to_s)
    redirect_to({:controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder})
  rescue DmsfAccessError
    render_403
  end

  def entries_email
    @email_params = params[:email]
    if @email_params["to"].strip.blank?
      flash.now[:error] = l(:error_email_to_must_be_entered)
      render :action => "email_entries"
      return
    end
    DmsfMailer.deliver_send_documents(User.current, @email_params["to"], @email_params["cc"],
      @email_params["subject"], @email_params["zipped_content"], @email_params["body"])
    File.delete(@email_params["zipped_content"])
    flash[:notice] = l(:notice_email_sent)
    redirect_to({:controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder})
  end

  class ZipMaxFilesError < StandardError
  end

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
    
    redirect_to :controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder
  end

  # Folder manipulation

  def new
    @pathfolder = @parent
    render :action => "edit"
  end

  def create
    @folder = DmsfFolder.new(params[:dmsf_folder])
    @folder.project = @project
    @folder.folder = @parent
    @folder.user = User.current
    if @folder.save
      flash[:notice] = l(:notice_folder_created)
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} created folder #{@project.identifier}://#{@folder.dmsf_path_str}"
      redirect_to({:controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder})
    else
      @pathfolder = @parent
      render :action => "edit"
    end
  end

  def edit
    @parent = @folder.folder
    @pathfolder = copy_folder(@folder)
  end

  def save
    unless params[:dmsf_folder]
      redirect_to :controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder
      return
    end
    @pathfolder = copy_folder(@folder)
    @folder.attributes = params[:dmsf_folder]
    if @folder.save
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} updated folder #{@project.identifier}://#{@folder.dmsf_path_str}"
      flash[:notice] = l(:notice_folder_details_were_saved)
      redirect_to :controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder
    else
      render :action => "edit"
    end
  end

  def delete
    check_project(@delete_folder = DmsfFolder.find(params[:delete_folder_id]))
    if !@delete_folder.nil?
      if @delete_folder.delete
        flash[:notice] = l(:notice_folder_deleted)
        Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} deleted folder #{@project.identifier}://#{@delete_folder.dmsf_path_str}"
      else
        flash[:error] = l(:error_folder_is_not_empty)
      end
    end
    redirect_to :controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder
  rescue DmsfAccessError
    render_403  
  end

  def edit_root
  end

  def save_root
    @project.dmsf_description = params[:project][:dmsf_description]
    @project.save!
    flash[:notice] = l(:notice_folder_details_were_saved)
    redirect_to :controller => "dmsf", :action => "show", :id => @project
  end

  def notify_activate
    if @folder.notification
      flash[:warning] = l(:warning_folder_notifications_already_activated)
    else
      @folder.notify_activate
      flash[:notice] = l(:notice_folder_notifications_activated)
    end
    redirect_to params[:current] ? params[:current] : 
      {:controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder.folder}
  end
  
  def notify_deactivate
    if !@folder.notification
      flash[:warning] = l(:warning_folder_notifications_already_deactivated)
    else
      @folder.notify_deactivate
      flash[:notice] = l(:notice_folder_notifications_deactivated)
    end
    redirect_to params[:current] ? params[:current] : 
      {:controller => "dmsf", :action => "show", :id => @project, :folder_id => @folder.folder}
  end

  private

  def email_entries(selected_folders, selected_files)
    zip = DmsfZip.new
    zip_entries(zip, selected_folders, selected_files)
    
    ziped_content = "#{DmsfHelper.temp_dir}/#{DmsfHelper.temp_filename("dmsf_email_sent_documents.zip")}";
    
    File.open(ziped_content, "wb") do |f|
      zip_file = File.open(zip.finish, "rb")
      while (buffer = zip_file.read(8192))
        f.write(buffer)
      end
    end
    
    Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} emailed from project #{@project.identifier}:"
    selected_folders.each {|folder| Rails.logger.info "\tFolder #{folder}"} unless selected_folders.nil?
    selected_files.each {|file| Rails.logger.info "\tFile #{file}"} unless selected_files.nil?
    
    @email_params = {"zipped_content" => ziped_content}
    render :action => "email_entries"
  ensure
    zip.close unless zip.nil? 
  end

  def download_entries(selected_folders, selected_files)
    zip = DmsfZip.new
    zip_entries(zip, selected_folders, selected_files)
    
    Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} downloaded from project #{@project.identifier}:"
    selected_folders.each {|folder| Rails.logger.info "\tFolder #{folder}"} unless selected_folders.nil?
    selected_files.each {|file| Rails.logger.info "\tFile #{file}"} unless selected_files.nil?
    
    send_file(zip.finish, 
      :filename => filename_for_content_disposition(@project.name + "-" + DateTime.now.strftime("%y%m%d%H%M%S") + ".zip"),
      :type => "application/zip", 
      :disposition => "attachment")
  ensure
    zip.close unless zip.nil? 
  end
  
  def zip_entries(zip, selected_folders, selected_files)
    if selected_folders && selected_folders.is_a?(Array)
      selected_folders.each do |selected_folder_id|
        check_project(folder = DmsfFolder.find(selected_folder_id))
        zip.add_folder(folder) unless folder.nil?
      end
    end
    if selected_files && selected_files.is_a?(Array)
      selected_files.each do |selected_file_id|
        check_project(file = DmsfFile.find(selected_file_id))
        zip.add_file(file) unless file.nil?
      end
    end
    
    max_files = 0
    max_files = Setting.plugin_redmine_dmsf["dmsf_max_file_download"].to_i
    if max_files > 0 && zip.file_count > max_files
      raise ZipMaxFilesError, zip.file_count
    end
    
    zip
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

  def check_project(entry)
    if !entry.nil? && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end
  end

  def copy_folder(folder)
    copy = folder.clone
    copy.id = folder.id
    copy
  end

end
