# encoding: utf-8
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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

class DmsfUploadController < ApplicationController
  unloadable
  
  menu_item :dmsf
  
  before_filter :find_project
  before_filter :authorize
  before_filter :find_folder, :except => [:upload_file, :upload, :commit]
  
  helper :all
  helper :dmsf_workflows
  
  accept_api_auth :upload, :commit

  def upload_files
    uploaded_files = params[:attachments]
    @uploads = []
    if uploaded_files && uploaded_files.is_a?(Hash)
      # standard file input uploads
      uploaded_files.each_value do |uploaded_file|        
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
        @uploads.push(upload) if upload
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

  # async single file upload handling 
  def upload_file    
    @tempfile = params[:file]    
    unless @tempfile.original_filename
      render_404
      return
    end
    @disk_filename = DmsfHelper.temp_filename(@tempfile.original_filename)
    begin
      FileUtils.cp @tempfile.path, "#{DmsfHelper.temp_dir}/#{@disk_filename}"
    rescue Exception => e
      Rails.logger.error e.message
    end
    if File.size("#{DmsfHelper.temp_dir}/#{@disk_filename}") <= 0
      begin
        File.delete "#{DmsfHelper.temp_dir}/#{@disk_filename}"
      rescue Exception => e
        Rails.logger.error e.message
      end
      render :layout => nil, :json => { :jsonrpc => '2.0', 
        :error => { 
          :code => 103, 
          :message => l(:header_minimum_filesize), 
          :details => l(:error_minimum_filesize, 
          :file => @tempfile.original_filename.to_s) 
        }
      }
    else
      render :layout => false
    end
  end
  
  # REST API document upload
  def upload    
    unless request.content_type == 'application/octet-stream'
      render :nothing => true, :status => 406
      return
    end

    @attachment = Attachment.new(:file => request.raw_post)
    @attachment.author = User.current
    @attachment.filename = params[:filename].presence || Redmine::Utils.random_hex(16)
    @attachment.content_type = params[:content_type].presence
    saved = @attachment.save

    respond_to do |format|
      format.js
      format.api {
        if saved
          render :action => 'upload', :status => :created
        else
          render_validation_errors(@attachment)
        end
      }
    end
  end
  
  def commit_files    
    commit_files_internal params[:commited_files]
  end    
  
  # REST API file commit
  def commit
    attachments = params[:attachments]    
    if attachments && attachments.is_a?(Hash)
      @folder = DmsfFolder.visible.find_by_id attachments[:folder_id].to_i if attachments[:folder_id].present?
      # standard file input uploads
      uploaded_files = attachments.select { |key, value| key == 'uploaded_file'}
      uploaded_files.each_value do |uploaded_file|        
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
        uploaded_file[:disk_filename] = upload.disk_filename
      end
    end
    commit_files_internal uploaded_files   
  end

  private
  
  def commit_files_internal(commited_files)
    if commited_files && commited_files.is_a?(Hash)
      @files = []
      failed_uploads = []
      commited_files.each_value do |commited_file|
        name = commited_file[:name]
        
        new_revision = DmsfFileRevision.new
        file = DmsfFile.visible.find_file_by_name(@project, @folder, name)
        unless file
          link = DmsfLink.find_link_by_file_name(@project, @folder, name)
          file = link.target_file if link
        end
        
        unless file
          file = DmsfFile.new
          file.project = @project
          file.name = name
          file.folder = @folder
          file.notification = Setting.plugin_redmine_dmsf[:dmsf_default_notifications].present?          
          new_revision.minor_version = 0
          new_revision.major_version = 0
        else
          if file.locked_for_user?
            failed_uploads.push(commited_file)
            next
          end
          if file.last_revision
            last_revision = file.last_revision
            new_revision.source_revision = last_revision
            new_revision.major_version = last_revision.major_version
            new_revision.minor_version = last_revision.minor_version          
          else
            new_revision.minor_version = 0
            new_revision.major_version = 0
          end
        end

        commited_disk_filepath = "#{DmsfHelper.temp_dir}/#{commited_file[:disk_filename].gsub(/[\/\\]/,'')}"
                        
        new_revision.file = file
        new_revision.user = User.current
        new_revision.name = name
        new_revision.title = commited_file[:title]
        new_revision.description = commited_file[:description]
        new_revision.comment = commited_file[:comment]
        version = commited_file[:version].to_i
        if version == 3
          new_revision.major_version = commited_file[:custom_version_major].to_i
          new_revision.minor_version = commited_file[:custom_version_minor].to_i
        else
          new_revision.increase_version(version, true)                
        end
        new_revision.mime_type = Redmine::MimeType.of(new_revision.name)
        new_revision.size = File.size(commited_disk_filepath)

        if file.locked?
          begin
            file.unlock!
            flash[:notice] = l(:notice_file_unlocked)
          rescue DmsfLockError => e
            flash[:error] = e.message
            next
          end
        end
        
        # Need to save file first to generate id for it in case of creation. 
        # File id is needed to properly generate revision disk filename                
        if commited_file[:dmsf_file_revision].present?
          commited_file[:dmsf_file_revision][:custom_field_values].each_with_index do |v, i|
            new_revision.custom_field_values[i].value = v[1]
          end
        end
                       
        if new_revision.valid? && file.save
          new_revision.disk_filename = new_revision.new_storage_filename
        else
          failed_uploads.push(commited_file)
          next
        end
        
        if new_revision.save
          new_revision.assign_workflow(commited_file[:dmsf_workflow_id])                              
          FileUtils.mv(commited_disk_filepath, new_revision.disk_file)
          file.set_last_revision new_revision
          @files.push(file)
        else
          failed_uploads.push(commited_file)
        end
      end
      unless @files.empty?        
        @files.each { |file| log_activity(file, 'uploaded') if file }        
        if (@folder && @folder.notification?) || (!@folder && @project.dmsf_notification?)
          begin
            recipients = DmsfMailer.get_notify_users(@project, @files)
            recipients.each do |u|
              DmsfMailer.files_updated(u, @project, @files).deliver
            end          
            if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
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
      end
      unless failed_uploads.empty?
        flash[:warning] = l(:warning_some_files_were_not_commited, :files => failed_uploads.map{|u| u['name']}.join(', '))
      end
    end
    respond_to do |format|
      format.js
      format.api  {         
          render_validation_errors(failed_uploads) unless failed_uploads.empty?        
      }
      format.html { redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder) }
    end
    
  end
  
  def log_activity(file, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{file.project.identifier}/#{file.id}/#{file.last_revision.id}"
  end
    
  def find_folder
    @folder = DmsfFolder.visible.find(params[:folder_id]) if params.keys.include?('folder_id')    
  rescue DmsfAccessError
    render_403
  end
   
end
