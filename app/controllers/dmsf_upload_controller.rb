# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011 Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2014 Karel Pičman <karel.picman@kontron.com>
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
  before_filter :find_folder, :except => [:upload_file]
  
  helper :all
  helper :dmsf_workflows

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

  # async single file upload handling 
  def upload_file
    @tempfile = params[:file]
    unless @tempfile.original_filename
      render_404
      return
    end
    @disk_filename = DmsfHelper.temp_filename(@tempfile.original_filename)
    File.open("#{DmsfHelper.temp_dir}/#{@disk_filename}", 'wb') do |f| 
      while (buffer = @tempfile.read(8192))
        f.write(buffer)
      end
    end
    if File.size("#{DmsfHelper.temp_dir}/#{@disk_filename}") <= 0
      begin
        File.delete("#{DmsfHelper.temp_dir}/#{@disk_filename}")
      rescue
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
  
  def commit_files
    commited_files = params[:commited_files]
    if commited_files && commited_files.is_a?(Hash)
      files = []
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
          last_revision = file.last_revision
          new_revision.source_revision = last_revision
          new_revision.major_version = last_revision.major_version
          new_revision.minor_version = last_revision.minor_version          
        end

        commited_disk_filepath = "#{DmsfHelper.temp_dir}/#{commited_file[:disk_filename].gsub(/[\/\\]/,'')}"
        
        new_revision.project = link ? link.target_project : @project
        new_revision.folder = link ? link.target_folder : @folder
        new_revision.file = file
        new_revision.user = User.current
        new_revision.name = name
        new_revision.title = commited_file[:title]
        new_revision.description = commited_file[:description]
        new_revision.comment = commited_file[:comment]
        new_revision.increase_version(commited_file[:version].to_i, true)                
        new_revision.mime_type = Redmine::MimeType.of(new_revision.name)
        new_revision.size = File.size(commited_disk_filepath)

        file_upload = File.new(commited_disk_filepath, 'rb')
        unless file_upload
          failed_uploads.push(commited_file)
          flash[:error] = l(:error_file_commit_require_uploaded_file)
          next
        end
        
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
          new_revision.copy_file_content(file_upload)
          file_upload.close
          File.delete(commited_disk_filepath)          
          file.set_last_revision new_revision
          files.push(file)
        else
          failed_uploads.push(commited_file)
        end
      end
      unless files.empty?        
        files.each { |file| log_activity(file, 'uploaded') if file }        
        begin
          recipients = DmsfMailer.get_notify_users(User.current, files)
          recipients.each do |u|
            DmsfMailer.files_updated(u, @project, files).deliver
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
      unless failed_uploads.empty?
        flash[:warning] = l(:warning_some_files_were_not_commited, :files => failed_uploads.map{|u| u['name']}.join(', '))
      end
    end
    redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder)
  end

  private
  
  def log_activity(file, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{file.project.identifier}/#{file.id}/#{file.last_revision.id}"
  end
    
  def find_folder
    @folder = DmsfFolder.visible.find(params[:folder_id]) if params.keys.include?('folder_id')    
  rescue DmsfAccessError
    render_403
  end
   
end