# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Pičman <karel.picman@kontron.com>
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
  
  class ZipMaxFilesError < StandardError; end
  class EmailMaxFileSize < StandardError; end  
  class FileNotFound < StandardError; end
  
  before_filter :find_project
  before_filter :authorize
  before_filter :find_folder, :except => [:new, :create, :edit_root, :save_root]
  before_filter :find_parent, :only => [:new, :create]
  
  helper :all

  def show
    @folder_manipulation_allowed = User.current.allowed_to?(:folder_manipulation, @project)
    @file_manipulation_allowed = User.current.allowed_to?(:file_manipulation, @project)
    @force_file_unlock_allowed = User.current.allowed_to?(:force_file_unlock, @project)
    
    @workflows_available = DmsfWorkflow.where(['project_id = ? OR project_id IS NULL', @project.id]).count > 0
    
    unless @folder
      if params[:custom_field_id].present? && params[:custom_value].present?
        @subfolders = []
        DmsfFolder.where(:project_id => @project.id).visible.each do |f|
          f.custom_field_values.each do |v|            
            if v.custom_field_id == params[:custom_field_id].to_i
              if v.custom_field.compare_values?(v.value, params[:custom_value])
                @subfolders << f
                break
              end
            end
          end
        end
        @files = []
        DmsfFile.where(:project_id => @project.id).visible.each do |f|
          r = f.last_revision
          if r
            r.custom_field_values.each do |v|                            
              if v.custom_field_id == params[:custom_field_id].to_i
                if v.custom_field.compare_values?(v.value, params[:custom_value])
                  @files << f
                  break
                end                  
              end
            end
          end
        end
        @dir_links = []
        DmsfLink.where(:project_id => @project.id, :target_type => DmsfFolder.model_name).visible.each do |l|
          l.target_folder.custom_field_values.each do |v|              
            if v.custom_field_id == params[:custom_field_id].to_i
              if v.custom_field.compare_values?(v.value, params[:custom_value])
                @dir_links << l
                break
              end              
            end
          end
        end
        @file_links = []
        DmsfLink.where(:project_id => @project.id, :target_type => DmsfFile.model_name).visible.each do |l|
          r = l.target_file.last_revision
          if r
            r.custom_field_values.each do |v|              
              if v.custom_field_id == params[:custom_field_id].to_i
                if v.custom_field.compare_values?(v.value, params[:custom_value])
                  @file_links << l
                  break
                end               
              end
            end
          end
        end
      else
        @subfolders = @project.dmsf_folders.visible
        @files = @project.dmsf_files.visible     
        @dir_links = @project.folder_links.visible
        @file_links = @project.file_links.visible
      end
      @locked_for_user = false
    else 
      @subfolders = @folder.subfolders.visible
      @files = @folder.files.visible      
      @dir_links = @folder.folder_links.visible
      @file_links = @folder.file_links.visible
      @locked_for_user = @folder.locked_for_user?
    end
    
    @ajax_upload_size = Setting.plugin_redmine_dmsf['dmsf_max_ajax_upload_filesize'].present? ? Setting.plugin_redmine_dmsf['dmsf_max_ajax_upload_filesize'] : 100
  end
  
  def download_email_entries
    send_file(        
        params[:path],
        :filename => 'Documents.zip',
        :type => 'application/zip', 
        :disposition => 'attachment')
    rescue Exception => e
      flash[:error] = e.message    
  end

  def entries_operation    
    # Download/Email
    selected_folders = params[:subfolders].present? ? params[:subfolders] : []
    selected_files = params[:files].present? ? params[:files] : []
    selected_dir_links = params[:dir_links]
    selected_file_links = params[:file_links]
    
    if selected_folders.blank? && selected_files.blank? && 
      selected_dir_links.blank? && selected_file_links.blank?
      flash[:warning] = l(:warning_no_entries_selected)      
      redirect_to :back
      return
    end
    
    if selected_dir_links.present?
      selected_dir_links.each do |id|
        link = DmsfLink.find_by_id id
        selected_folders << link.target_id if link
      end
    end
    
    if selected_file_links.present?
      selected_file_links.each do |id|
        link = DmsfLink.find_by_id id
        selected_files << link.target_id if link
      end
    end
    
    if params[:email_entries].present?
      email_entries(selected_folders, selected_files)
    else
      download_entries(selected_folders, selected_files)
    end
  rescue ZipMaxFilesError
    flash[:error] = l(:error_max_files_exceeded, :number => Setting.plugin_redmine_dmsf['dmsf_max_file_download'])
    redirect_to :back
  rescue EmailMaxFileSize
    flash[:error] = l(:error_max_email_filesize_exceeded, :number => Setting.plugin_redmine_dmsf['dmsf_max_email_filesize'])
    redirect_to :back
  rescue FileNotFound
    render_404
  rescue DmsfAccessError
    render_403
  end
  
  def tag_changed
    # Tag filter
    if params[:dmsf_folder] && params[:dmsf_folder][:custom_field_values].present?
      redirect_to dmsf_folder_path(
        :id => @project,         
        :custom_field_id => params[:dmsf_folder][:custom_field_values].first[0],
        :custom_value => params[:dmsf_folder][:custom_field_values].first[1])
    else
      redirect_to :back
    end
  end

  def entries_email
    @email_params = params[:email]
    if @email_params[:to].strip.blank?
      flash.now[:error] = l(:error_email_to_must_be_entered)
      render :action => 'email_entries'
      return
    end    
    DmsfMailer.send_documents(@project, User.current, @email_params).deliver
    File.delete(@email_params['zipped_content'])
    flash[:notice] = l(:notice_email_sent, @email_params['to'])
    
    redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder)
  end 

  def delete_entries
    selected_folders = params[:subfolders]
    selected_files = params[:files]
    selected_dir_links = params[:dir_links]
    selected_file_links = params[:file_links]
    if selected_folders.blank? && selected_files.blank? && 
      selected_dir_links.blank? && selected_file_links.blank?
      flash[:warning] = l(:warning_no_entries_selected)
    else
      failed_entries = []            
                  
      if User.current.allowed_to?(:folder_manipulation, @project)
        # Folders
        if selected_folders.present?        
          selected_folders.each do |subfolderid|
            subfolder = DmsfFolder.visible.find_by_id subfolderid
            next unless subfolder
            if subfolder.project != @project || !subfolder.delete
              failed_entries.push(subfolder)      
            end
          end        
        end
        # Folder links
        if selected_dir_links.present?        
          selected_dir_links.each do |dir_link_id|
            link_folder = DmsfLink.visible.find_by_id dir_link_id
            next unless link_folder
            if link_folder.project != @project || !link_folder.delete
              failed_entries.push(link_folder)      
            end
          end        
        end
      else
        flash[:error] = l(:error_user_has_not_right_delete_folder)
      end
      
      deleted_files = []
      if User.current.allowed_to?(:file_manipulation, @project)
        # Files
        if selected_files.present?        
          selected_files.each do |fileid|
            file = DmsfFile.visible.find_by_id fileid
            next unless file
            if file.project != @project || !file.delete
              failed_entries.push(file)
            else
              deleted_files.push(file)
            end
          end        
        end
        # File links
        if selected_file_links.present?        
          selected_file_links.each do |file_link_id|
            file_link = DmsfLink.visible.find_by_id file_link_id
            next unless file_link
            if file_link.project != @project || !file_link.delete
              failed_entries.push(file_link)            
            end
          end        
        end
      else
        flash[:error] = l(:error_user_has_not_right_delete_file)
      end
      
      unless deleted_files.empty?
        deleted_files.each do |f| 
          log_activity(f, 'deleted')
        end
        begin
          DmsfMailer.get_notify_users(User.current, deleted_files).each do |u|
            DmsfMailer.files_deleted(u, @project, deleted_files).deliver
          end
        rescue Exception => e
          Rails.logger.error "Could not send email notifications: #{e.message}"
        end
      end
      if failed_entries.empty?
        flash[:notice] = l(:notice_entries_deleted)
      else
        flash[:warning] = l(:warning_some_entries_were_not_deleted, :entries => failed_entries.map{|e| e.title}.join(', '))
      end
    end
        
    redirect_to :back
  end

  # Folder manipulation

  def new
    @folder = DmsfFolder.new
    @pathfolder = @parent
    render :action => 'edit'
  end

  def create
    @folder = DmsfFolder.new(params[:dmsf_folder])
    @folder.project = @project
    @folder.user = User.current
    if @folder.save
      flash[:notice] = l(:notice_folder_created)
      redirect_to({:controller => 'dmsf', :action => 'show', :id => @project, :folder_id => @folder})
    else
      @pathfolder = @parent
      render :action => 'edit'
    end
  end

  def edit
    @parent = @folder.folder
    @pathfolder = copy_folder(@folder)
  end

  def save
    unless params[:dmsf_folder]
      redirect_to :controller => 'dmsf', :action => 'show', :id => @project, :folder_id => @folder
      return
    end
    @pathfolder = copy_folder(@folder)
    @folder.attributes = params[:dmsf_folder]
    if @folder.save
      flash[:notice] = l(:notice_folder_details_were_saved)
      redirect_to :controller => 'dmsf', :action => 'show', :id => @project, :folder_id => @folder
    else
      render :action => 'edit'
    end
  end

  def delete    
    @delete_folder = DmsfFolder.visible.find(params[:delete_folder_id])
    if @delete_folder
      if @delete_folder.delete
        flash[:notice] = l(:notice_folder_deleted)
      else
        flash[:error] = @delete_folder.errors[:base][0]
      end
    end    
    redirect_to dmsf_folder_path(:id => @project, :folder_id => @delete_folder.dmsf_folder_id)
  rescue DmsfAccessError
    render_403  
  end

  def edit_root
  end

  def save_root
    @project.dmsf_description = params[:project][:dmsf_description]
    @project.save!
    flash[:notice] = l(:notice_folder_details_were_saved)
    redirect_to :controller => 'dmsf', :action => 'show', :id => @project
  end

  def notify_activate        
    if((@folder && @folder.notification) || (@folder.nil? && @project.dmsf_notification))
      flash[:warning] = l(:warning_folder_notifications_already_activated)
    else
      if @folder
        @folder.notify_activate
      else
        @project.dmsf_notification = true
        @project.save
      end
      flash[:notice] = l(:notice_folder_notifications_activated)
    end    
    redirect_to :back
  end
  
  def notify_deactivate
    if((@folder && !@folder.notification) || (@folder.nil? && !@project.dmsf_notification))
      flash[:warning] = l(:warning_folder_notifications_already_deactivated)
    else
      if @folder
        @folder.notify_deactivate
      else
        @project.dmsf_notification = false
        @project.save
      end
      flash[:notice] = l(:notice_folder_notifications_deactivated)
    end    
    redirect_to :back
  end

  def lock
    if @folder.nil?
      flash[:warning] = l(:warning_foler_unlockable)
    elsif @folder.locked?
      flash[:warning] = l(:warning_folder_already_locked)
    else
      @folder.lock!
      flash[:notice] = l(:notice_folder_locked)
    end      
      redirect_to :back
  end

  def unlock
    if @folder.nil?
      flash[:warning] = l(:warning_foler_unlockable)
    elsif !@folder.locked?
      flash[:warning] = l(:warning_folder_not_locked)
    else
      if @folder.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @project)
        @folder.unlock!
        flash[:notice] = l(:notice_folder_unlocked)
      else
        flash[:error] = l(:error_only_user_that_locked_folder_can_unlock_it)
      end
    end    
     redirect_to :back
  end
  
  private

  def log_activity(file, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{file.project.identifier}/#{file.id}"
  end

  def email_entries(selected_folders, selected_files)
    begin
      zip = DmsfZip.new
      zip_entries(zip, selected_folders, selected_files)

      zipped_content = "#{DmsfHelper.temp_dir}/#{DmsfHelper.temp_filename('dmsf_email_sent_documents.zip')}";

      File.open(zipped_content, 'wb') do |f|
        zip_file = File.open(zip.finish, 'rb')
        while (buffer = zip_file.read(8192))
          f.write(buffer)
        end
      end

      max_filesize = Setting.plugin_redmine_dmsf['dmsf_max_email_filesize'].to_f
      if max_filesize > 0 && File.size(zipped_content) > max_filesize * 1048576
        raise EmailMaxFileSize
      end

      zip.files.each do |f| 
        log_activity(f, 'emailing zip')
        audit = DmsfFileRevisionAccess.new(:user_id => User.current.id, :dmsf_file_revision_id => f.last_revision.id, 
          :action => DmsfFileRevisionAccess::EmailAction)
        audit.save!
      end

      @email_params = { 
        :zipped_content => zipped_content,
        :folders => selected_folders,
        :files => selected_files
      }
      render :action => 'email_entries'
    rescue Exception => e
      flash[:error] = e.message
    ensure
      zip.close if zip
    end
  end

  def download_entries(selected_folders, selected_files)
    begin
      zip = DmsfZip.new
      zip_entries(zip, selected_folders, selected_files)

      zip.files.each do |f| 
        log_activity(f, 'download zip')
        audit = DmsfFileRevisionAccess.new(:user_id => User.current.id, :dmsf_file_revision_id => f.last_revision.id, 
          :action => DmsfFileRevisionAccess::DownloadAction)
        audit.save!
      end

      send_file(zip.finish, 
        :filename => filename_for_content_disposition("#{@project.name}-#{DateTime.now.strftime('%y%m%d%H%M%S')}.zip"),
        :type => 'application/zip', 
        :disposition => 'attachment')
    rescue Exception => e
      flash[:error] = e.message
    ensure
      zip.close if zip
    end
  end
  
  def zip_entries(zip, selected_folders, selected_files)    
    if selected_folders && selected_folders.is_a?(Array)
      selected_folders.each do |selected_folder_id|        
        folder = DmsfFolder.visible.find(selected_folder_id)
        zip.add_folder(folder, (@folder.dmsf_path_str if @folder)) if folder
      end
    end
    if selected_files && selected_files.is_a?(Array)
      selected_files.each do |selected_file_id|        
        file = DmsfFile.visible.find(selected_file_id)
        if file && file.last_revision && File.exists?(file.last_revision.disk_file)
          zip.add_file(file, (@folder.dmsf_path_str if @folder)) if file          
        else
          raise FileNotFound
        end        
      end
    end
    max_files = Setting.plugin_redmine_dmsf['dmsf_max_file_download'].to_i
    if max_files > 0 && zip.files.length > max_files
      raise ZipMaxFilesError, zip.files.length
    end    
    zip
  end
  
  def find_folder
    @folder = DmsfFolder.visible.find(params[:folder_id]) if params.keys.include?('folder_id')    
  rescue DmsfAccessError
    render_403
  end

  def find_parent
    @parent = DmsfFolder.visible.find(params[:parent_id]) if params.keys.include?('parent_id')    
  rescue DmsfAccessError
    render_403
  end

  def copy_folder(folder)
    copy = folder.clone
    copy.id = folder.id
    copy
  end

end