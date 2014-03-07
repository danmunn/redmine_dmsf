# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-14 Karel Pičman <karel.picman@lbcfree.net>
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

class DmsfLinksController < ApplicationController
  unloadable
    
  model_object DmsfLink
  before_filter :find_model_object, :only => [:destroy]
  before_filter :find_link_project
  before_filter :authorize  

  def new        
    @dmsf_link = DmsfLink.new(:project_id => params[:project_id])
    
    if params[:dmsf_link].present?        
      # Reload
      @dmsf_link.dmsf_folder_id = params[:dmsf_link][:dmsf_folder_id]
      @dmsf_file_id = params[:dmsf_link][:dmsf_file_id]
      @type = params[:dmsf_link][:type]
      @dmsf_link.target_project_id = params[:dmsf_link][:target_project_id]      
      @target_folder_id = params[:dmsf_link][:target_folder_id].to_i if params[:reload].blank? && DmsfLinksHelper.is_a_number?(params[:dmsf_link][:target_folder_id])      
      if @type == 'link_to'
        if params[:dmsf_link][:dmsf_file_id].present?
          file = DmsfFile.find_by_id params[:dmsf_link][:dmsf_file_id]
          @dmsf_link.name = file.title if file
        else
          folder = DmsfFolder.find_by_id params[:dmsf_link][:dmsf_folder_id]
          @dmsf_link.name = folder.title if folder
        end
      else          
        if params[:dmsf_link][:target_file_id].present?
          @target_file_id = params[:dmsf_link][:target_file_id]
          file = DmsfFile.find_by_id @target_file_id

          if file
            folder = DmsfFolder.find_by_id params[:dmsf_link][:target_folder_id]
            if (folder && (folder.project_id == @dmsf_link.target_project_id) && folder.files.include?(file)) || folder.nil?
              @dmsf_link.name = file.title
            end
          end            
        else
          folder = DmsfFolder.find_by_id params[:dmsf_link][:target_folder_id]

          if folder
            if folder.project_id == @dmsf_link.target_project_id
              @dmsf_link.name = folder.title if folder
            end
          end                      
        end
      end      
    else
      # Link from/to
      @dmsf_link.dmsf_folder_id = params[:dmsf_folder_id]
      @dmsf_file_id = params[:dmsf_file_id]
      @type = params[:type]
      @dmsf_link.target_project_id = params[:project_id]
      @target_folder_id = params[:dmsf_folder_id].to_i if params[:dmsf_folder_id].present?
      if @type == 'link_to'
        if @dmsf_file_id
          file = DmsfFile.find_by_id @dmsf_file_id
          @dmsf_link.name = file.title if file
        else
          folder = DmsfFolder.find_by_id @target_folder_id
          @dmsf_link.name = folder.title if folder
        end
      end
    end        
    
    render :layout => !request.xhr?
  end
   
  def create
    @dmsf_link = DmsfLink.new
    
    if params[:dmsf_link][:type] == 'link_from'
      # Link from
      @dmsf_link.project_id = params[:dmsf_link][:project_id]
      @dmsf_link.dmsf_folder_id = params[:dmsf_link][:dmsf_folder_id]
      @dmsf_link.target_project_id = params[:dmsf_link][:target_project_id]
      if params[:dmsf_link][:target_file_id].present?
        @dmsf_link.target_id = params[:dmsf_link][:target_file_id]
        @dmsf_link.target_type = DmsfFile.model_name
      else
        @dmsf_link.target_id = DmsfLinksHelper.is_a_number?(params[:dmsf_link][:target_folder_id]) ? params[:dmsf_link][:target_folder_id].to_i : nil
        @dmsf_link.target_type = DmsfFolder.model_name
      end        
      @dmsf_link.name = params[:dmsf_link][:name]  
                     
      if @dmsf_link.save
        flash[:notice] = l(:notice_successful_create)      
        redirect_to dmsf_folder_path(:id => @project.id, :folder_id => @dmsf_link.dmsf_folder_id)
      else         
        @dmsf_file_id = params[:dmsf_link][:dmsf_file_id]
        @type = params[:dmsf_link][:type]        
        @target_folder_id = params[:dmsf_link][:target_folder_id].to_i if DmsfLinksHelper.is_a_number?(params[:dmsf_link][:target_folder_id])                        
        @target_file_id = @dmsf_link.target_id if @dmsf_link.target_type == DmsfFile.model_name
        render :action => 'new'
      end
    else
      # Link to      
      @dmsf_link.project_id = params[:dmsf_link][:target_project_id]
      @dmsf_link.dmsf_folder_id = DmsfLinksHelper.is_a_number?(params[:dmsf_link][:target_folder_id]) ? params[:dmsf_link][:target_folder_id].to_i : nil
      @dmsf_link.target_project_id = params[:dmsf_link][:project_id]
      if params[:dmsf_link][:dmsf_file_id].present?        
        @dmsf_link.target_id = params[:dmsf_link][:dmsf_file_id]
        @dmsf_link.target_type = DmsfFile.model_name
      else        
        @dmsf_link.target_id = params[:dmsf_link][:dmsf_folder_id]
        @dmsf_link.target_type = DmsfFolder.model_name
      end
      @dmsf_link.name = params[:dmsf_link][:name]  
                     
      if @dmsf_link.save        
        flash[:notice] = l(:notice_successful_create)
        if params[:dmsf_link][:dmsf_file_id].present?
          redirect_to dmsf_file_path(@dmsf_link.target_file)
        else          
          redirect_to edit_dmsf_path(:id => params[:dmsf_link][:project_id], :folder_id => params[:dmsf_link][:dmsf_folder_id])          
        end
      else
        @dmsf_file_id = params[:dmsf_link][:dmsf_file_id]
        @type = params[:dmsf_link][:type]        
        @target_folder_id = @dmsf_link.dmsf_folder_id        
        @dmsf_link.target_project_id = @dmsf_link.project.id
        @dmsf_link.project_id = params[:dmsf_link][:project_id]
        @dmsf_link.dmsf_folder_id = params[:dmsf_link][:dmsf_folder_id]
        render :action => 'new'
      end
    end        
  end
  
  def destroy    
    begin
      @dmsf_link.destroy 
      flash[:notice] = l(:notice_successful_delete)
    rescue
      flash[:error] = l(:error_unable_delete_dmsf_workflow)
    end
    
    redirect_to :back
  end
 
  private
  
  def find_link_project
    if @dmsf_link
      @project = @dmsf_link.project
    else
      @project = Project.find(params[:dmsf_link].present? ? params[:dmsf_link][:project_id] : params[:project_id])      
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
 
end