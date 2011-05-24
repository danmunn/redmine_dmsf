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
  before_filter :authorize
  before_filter :find_folder, :only => [:index, :entries_operation, :email_entries_send]
  before_filter :find_file, :only => [:download_file]
  
  helper :sort
  include SortHelper
  
  def index
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
    
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.api
    end 
    
  end

  def download_file
    if @file.deleted
      render_404
    else
      @revision = @file.last_revision
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} downloaded #{@project.identifier}://#{@file.dmsf_path_str} revision #{@revision.id}"
      send_revision
    end
  end

  def download_revision
    @revision = DmsfFileRevision.find(params[:revision_id])
    if @revision.deleted
      render_404
    else
      Rails.logger.info "#{Time.now} from #{request.remote_ip}/#{request.env["HTTP_X_FORWARDED_FOR"]}: #{User.current.login} downloaded #{@project.identifier}://#{@revision.file.dmsf_path_str} revision #{@revision.id}"
      check_project(@revision.file)
      send_revision
    end
  rescue DmsfAccessError
    render_403
  end

  def entries_operation
    selected_folders = params[:subfolders]
    selected_files = params[:files]
    
    if selected_folders.nil? && selected_files.nil?
      flash[:warning] = l(:warning_no_entries_selected)
      redirect_to :action => "index", :id => @project, :folder_id => @folder
      return
    end
    
    if !params[:email_entries].blank?
      email_entries(selected_folders, selected_files)
    else
      download_entries(selected_folders, selected_files)
    end
  rescue ZipMaxFilesError
    flash[:error] = l(:error_max_files_exceeded, :number => Setting.plugin_redmine_dmsf["dmsf_max_file_download"].to_i.to_s)
    redirect_to({:controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder})
  rescue DmsfAccessError
    render_403
  end

  def email_entries_send
    @email_params = params[:email]
    if @email_params["to"].strip.blank?
      flash[:error] = l(:error_email_to_must_be_entered)
      render :action => "email_entries"
      return
    end
    DmsfMailer.deliver_send_documents(User.current, @email_params["to"], @email_params["cc"],
      @email_params["subject"], @email_params["zipped_content"], @email_params["body"])
    File.delete(@email_params["zipped_content"])
    flash[:notice] = l(:notice_email_sent)
    redirect_to({:controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder})
  end

  class ZipMaxFilesError < StandardError
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
  
  def send_revision
    send_file(@revision.disk_file, 
      :filename => filename_for_content_disposition(@revision.name),
      :type => @revision.detect_content_type, 
      :disposition => "attachment")
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
