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

class DmsfFoldersCopyController < ApplicationController
  unloadable
  
  menu_item :dmsf
  
  before_filter :find_folder
  before_filter :authorize

  def new
    @target_project = DmsfFolder.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
    @target_project ||= @project if User.current.allowed_to?(:folder_manipulation, @project)
    if DmsfFile.allowed_target_projects_on_copy.blank?
      flash.now[:warning] = l(:warning_no_project_to_copy_folder_to)
    else
      @target_project ||= DmsfFolder.allowed_target_projects_on_copy[0]
    end
    
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    @target_folder ||= @folder.folder if @target_project == @project
    
    render :layout => !request.xhr?
  end

  def copy_to
    @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
    unless @target_project
      render_403
      return
    end
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    if !@target_folder.nil? && @target_folder.project != @target_project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end

    if (@target_folder && @target_folder == @folder.folder) || 
        (@target_folder.nil? && @folder.folder.nil? && @target_project == @folder.project)
      flash[:error] = l(:error_target_folder_same)
      redirect_to :action => 'new', :id => @folder, :target_project_id => @target_project, :target_folder_id => @target_folder
      return
    end

    new_folder = @folder.copy_to(@target_project, @target_folder)
    
    unless new_folder.errors.empty?
      flash[:error] = "#{l(:error_folder_cannot_be_copied)}: #{new_folder.errors.full_messages.join(', ')}"
      redirect_to :action => 'new', :id => @folder, :target_project_id => @target_project, :target_folder_id => @target_folder
      return
    end

    new_folder.reload
    
    flash[:notice] = l(:notice_folder_copied)
    log_activity(new_folder, 'was copied (is copy)')
          
    redirect_to dmsf_folder_path(:id => @target_project, :folder_id => new_folder)
  end

  private

  def log_activity(folder, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{folder.project.identifier}/#{folder.id}"
  end

  def find_folder
    @folder = DmsfFolder.visible.find(params[:id])
    @project = @folder.project
  end
  
end
