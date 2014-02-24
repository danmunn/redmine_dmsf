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

  helper :all

  def new
    @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
    @target_project ||= @project if User.current.allowed_to?(:file_manipulation, @project)
    if DmsfFile.allowed_target_projects_on_copy.blank?
      flash.now[:warning] = l(:warning_no_project_to_copy_file_to)
    else
      @target_project ||= DmsfFile.allowed_target_projects_on_copy[0]
    end
    
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    @target_folder ||= @file.folder if @target_project == @project
    
    render :layout => !request.xhr?
  end

  def create
    @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
    unless @target_project
      render_403
      return
    end
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    if !@target_folder.nil? && @target_folder.project != @target_project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end

    if (@target_folder && @target_folder == @file.folder) || 
        (@target_folder.nil? && @file.folder.nil? && @target_project == @file.project)
      flash[:error] = l(:error_target_folder_same)
      redirect_to :action => 'new', :id => @file, :target_project_id => @target_project, :target_folder_id => @target_folder
      return
    end

    new_file = @file.copy_to(@target_project, @target_folder)
    
    unless new_file.errors.empty?
      flash[:error] = "#{l(:error_file_cannot_be_copied)}: #{new_file.errors.full_messages.join(', ')}"
      redirect_to :action => 'new', :id => @file, :target_project_id => @target_project, :target_folder_id => @target_folder
      return
    end

    flash[:notice] = l(:notice_file_copied)
    log_activity(new_file, 'was copied (is copy)')   
    
    redirect_to dmsf_file_path(new_file)
  end

  def move
    @target_project = DmsfFile.allowed_target_projects_on_copy.detect {|p| p.id.to_s == params[:target_project_id]} if params[:target_project_id]
    unless @target_project && User.current.allowed_to?(:file_manipulation, @target_project) && User.current.allowed_to?(:file_manipulation, @project)
      render_403
      return
    end
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    if @target_folder && @target_folder.project != @target_project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end

    if (@target_folder && @target_folder == @file.folder) || 
        (@target_folder.nil? && @file.folder.nil? && @target_project == @file.project)
      flash[:error] = l(:error_target_folder_same)
      redirect_to :action => 'new', :id => @file, :target_project_id => @target_project, :target_folder_id => @target_folder
      return
    end

    unless @file.move_to(@target_project, @target_folder)
      flash[:error] = "#{l(:error_file_cannot_be_moved)}: #{@file.errors.full_messages.join(', ')}"
      redirect_to :action => 'new', :id => @file, :target_project_id => @target_project, :target_folder_id => @target_folder
      return
    end

    @file.reload
    
    flash[:notice] = l(:notice_file_moved)
    log_activity(@file, 'was moved (is copy)')    
    
    redirect_to dmsf_file_path(@file)
  end

  private

  def log_activity(file, action)
    Rails.logger.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{User.current.login}@#{request.remote_ip}/#{request.env['HTTP_X_FORWARDED_FOR']}: #{action} dmsf://#{file.project.identifier}/#{file.id}/#{file.last_revision.id}"
  end

  def find_file
    @file = DmsfFile.visible.find(params[:id])
    @project = @file.project
  end
  
end
