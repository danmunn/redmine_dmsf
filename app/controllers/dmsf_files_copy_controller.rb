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

class DmsfFilesCopyController < ApplicationController
  unloadable
  
  menu_item :dmsf
  
  before_filter :find_file
  before_filter :authorize

  def new
    @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
    @target_project ||= @project if User.current.allowed_to?(:file_manipulation, @project)
    if DmsfFile.allowed_target_projects_on_copy.blank?
      flash.now[:warning] = l(:warning_no_project_to_copy_file_to)
    else
      @target_project ||= DmsfFile.allowed_target_projects_on_copy[0]
    end
    
    @target_folder = DmsfFolder.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    @target_folder ||= @file.folder if @target_project == @project
    
    render :layout => !request.xhr?
  end

  def create
    if request.post?
      @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
      unless @target_project
        render_403
        return
      end
      @target_folder = DmsfFolder.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
      if !@target_folder.nil? && @target_folder.project != @target_project
        raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
      end

      name = @file.name
      
      file = DmsfFile.find_file_by_name(@target_project, @target_folder, name)
      if file.nil?
        file = DmsfFile.new
        file.project = @target_project
        file.name = name
        file.folder = @target_folder
        file.notification = !Setting.plugin_redmine_dmsf["dmsf_default_notifications"].blank?
      else
        if file.locked_for_user?
          flash[:error] = l(:error_file_is_locked)
          redirect_to :action => "new", :id => @file, :target_project_id => @target_project, :target_folder_id => @target_folder
          return
        end
      end

      last_revision = @file.last_revision
      
      new_revision = DmsfFileRevision.new
      new_revision.folder = @target_folder
      new_revision.file = file
      new_revision.user = User.current
      new_revision.name = name
      new_revision.title = @file.title
      new_revision.description = @file.description
      new_revision.comment = l(:comment_copied_from, :source => "#{@project.identifier}:#{@file.dmsf_path_str}") 
      new_revision.source_revision = last_revision
      new_revision.major_version = last_revision.major_version
      new_revision.minor_version = last_revision.minor_version
      new_revision.workflow = last_revision.workflow
      new_revision.mime_type = last_revision.mime_type
      new_revision.size = last_revision.size
      new_revision.disk_filename = last_revision.disk_filename

      if file.save && new_revision.save
        file.reload
      else
        flash[:error] = error_messages_for(file)
        redirect_to :action => "new", :id => @file, :target_project_id => @target_project, :target_folder_id => @target_folder
        return
      end

      flash[:notice] = l(:notice_file_copied)
      log_activity(file, "was copied (is copy)")
      
      if params[:move]
        if User.current.allowed_to?(:file_manipulation, @project)
          if @file.delete
            flash[:notice] = l(:notice_file_moved)
            log_activity(@file, "was deleted")
            DmsfMailer.deliver_files_deleted(User.current, [@file])
          else
            flash[:error] = l(:error_file_is_locked)
          end
        else
          flash[:error] = l(:error_user_has_not_right_delete_file)
        end
      end
      
      redirect_to :controller => "dmsf_files", :action => "show", :id => file
    end
  end

  private

  def log_activity(file, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{file.project.identifier}/#{file.id}/#{file.last_revision.id}"
  end

  def find_file
    @file = DmsfFile.find(params[:id])
    @project = @file.project
  end
  
end
