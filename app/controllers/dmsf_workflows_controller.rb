# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013   Karel Picman <karel.picman@kontron.com>
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

class DmsfWorkflowsController < ApplicationController
  unloadable  
  layout :workflows_layout
  
  before_filter :find_workflow, :except => [:create, :new, :index]  
  before_filter :find_project   
  before_filter :authorize_global, :except => [:action, :new_action]
  
  def index    
    if @project
      @workflow_pages, @workflows = paginate DmsfWorkflow.where(:project_id => @project.id), :per_page => 25    
    else
      @workflow_pages, @workflows = paginate DmsfWorkflow.where(:project_id => nil), :per_page => 25    
    end
  end
  
  def action
  end
  
  def new_action
    logger.info '>>>>>>>>>>>>>>>>>>>>>>> YES!'
  end

  def log
  end
  
  def new   
    @workflow = DmsfWorkflow.new        
  end
  
  def create
    @workflow = DmsfWorkflow.new(:name => params[:dmsf_workflow][:name], :project_id => params[:project_id])
    if request.post? && @workflow.save
      flash[:notice] = l(:notice_successful_create)
      if @project
        redirect_to settings_project_path(@project, :tab => 'dmsf')
      else
        redirect_to dmsf_workflows_path
      end
    else      
      render :action => 'new'
    end
  end
  
  def edit       
  end   
  
  def update    
    if request.put? && @workflow.update_attributes({:name => params[:dmsf_workflow][:name]})
      flash[:notice] = l(:notice_successful_update)
      if @project
        redirect_to settings_project_path(@project, :tab => 'dmsf')
      else
        redirect_to dmsf_workflows_path
      end    
    else      
      render :action => 'edit'
    end
  end
  
  def destroy    
    begin
      @workflow.destroy    
    rescue
      flash[:error] = l(:error_unable_delete_dmsf_workflow)
    end
    if @project
      redirect_to settings_project_path(@project, :tab => 'dmsf')
    else
      redirect_to dmsf_workflows_path
    end    
  end
  
  def autocomplete_for_user
    respond_to do |format|      
      format.js
    end        
  end
  
  def add_step     
    if request.post?      
      users = User.find_all_by_id(params[:user_ids])      
      if params[:step] == '0'
        if @workflow.steps.count > 0
          step = @workflow.steps.last + 1
        else
          step = 1
        end
      else
        step = params[:step].to_i
      end
      operator = 1 ? params[:commit] == l(:dmsf_and) : 0      
      users.each do |user|
        @workflow.dmsf_workflow_steps << DmsfWorkflowStep.new(
          :dmsf_workflow_id => @workflow.id, 
          :step => step, 
          :user_id => user.id, 
          :operator => operator)
      end   
      @workflow.save      
    end             
    respond_to do |format|
      format.html            
    end        
  end
  
  def remove_step        
    if request.delete?
      DmsfWorkflowStep.where(:dmsf_workflow_id => @workflow.id, :step => params[:step]).each do |ws|
        @workflow.dmsf_workflow_steps.delete(ws)
      end              
      @workflow.dmsf_workflow_steps.each do |ws|
        n = ws.step.to_i
        if n > params[:step].to_i        
          ws.step = n - 1
          ws.save
        end
      end
    end        
    respond_to do |format|
      format.html      
    end
  end
  
  def reorder_steps    
    if request.put?
      @workflow.reorder_steps params[:step].to_i, params[:workflow_step][:move_to]      
    end        
    respond_to do |format|
      format.html      
    end
  end
  
  private    
  
  def find_workflow   
    @workflow = DmsfWorkflow.find_by_id(params[:id])    
  end
    
  def find_project    
    if @workflow
      @project = @workflow.project
    elsif params[:project_id].present?
       @project = Project.find_by_id params[:project_id]
    end              
  end
  
  def workflows_layout
    find_workflow
    find_project
    @project ? 'base' : 'admin'
  end
end
