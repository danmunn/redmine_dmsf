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
  
  before_filter :find_workflow, :except => [:create, :new, :index, :assign, :assignment]  
  before_filter :find_project, :except => [:start]
  before_filter :authorize_global  
  before_filter :authorize_custom      
  
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
    if params[:commit] == l(:button_submit)
      action = DmsfWorkflowStepAction.new(
        :dmsf_workflow_step_assignment_id => params[:dmsf_workflow_step_assignment_id],
        :action => (params[:step_action].to_i >= 10) ? DmsfWorkflowStepAction::ACTION_DELEGATE : params[:step_action],
        :note => params[:note])    
      if request.post?
        if action.save
          revision = DmsfFileRevision.find_by_id params[:dmsf_file_revision_id]
          if revision
            if @workflow.try_finish revision, action, (params[:step_action].to_i / 10)            
              file = DmsfFile.joins(:revisions).where(:dmsf_file_revisions => {:id => revision.id}).first
              file.unlock! if file              
              if revision.workflow == DmsfWorkflow::STATE_APPROVED
                # Just approved                                
                DmsfMailer.workflow_notification(
                  revision.file.project.members.collect{ |member| member.user.mail},
                  @workflow, 
                  revision,
                  "Approval workflow #{@workflow.name} approved",
                  'been finished and the document has been approved',
                  'To see the approval history click on the workflow status of the document in').deliver
              else
                # Just rejected
                owner = User.find_by_id revision.dmsf_workflow_assigned_by
                DmsfMailer.workflow_notification(
                  @workflow.participiants.collect{ |user| user.mail} << owner.mail, 
                  @workflow, 
                  revision,
                  "Approval workflow #{@workflow.name} rejected",
                  "been finished and the document has been rejected because of '#{action.note}'",
                  'To see the approval history click on the workflow status of the document in').deliver
              end
            else
              if action.action == DmsfWorkflowStepAction::ACTION_DELEGATE
                # Delegation                
                delegate = User.find_by_id params[:step_action].to_i / 10
                DmsfMailer.workflow_notification(
                  delegate.mail, 
                  @workflow, 
                  revision,
                  "Approval workflow #{@workflow.name} step delegated",
                  "been delegated  because of '#{action.note}' and you are expected to do an approval in the current approval step",
                  'To proceed click on the check box icon next to the document in').deliver
              else
                # Next step
                assignments = @workflow.next_assignments revision.id
                unless assignments.empty?
                  if assignments.first.dmsf_workflow_step.step != action.dmsf_workflow_step_assignment.dmsf_workflow_step.step
                    # Next step                  
                    DmsfMailer.workflow_notification(
                      assignments.collect{ |assignment| assignment.user.mail}, 
                      @workflow, 
                      revision,
                      "Approval workflow #{@workflow.name} requires your approval",
                      'finished one of the approval steps and you are expected to do an approval in the next approval step',
                      'To proceed click on the check box icon next to the document in the').deliver
                    owner = User.find_by_id revision.dmsf_workflow_assigned_by
                    DmsfMailer.workflow_notification(
                      owner.mail, 
                      @workflow, 
                      revision,
                      "Approval workflow #{@workflow.name} updated",
                      'finished one of the approval steps',
                      'To see the current status of the approval workflow click on the workflow status the document in').deliver
                  end
                end
              end
            end
          end
          flash[:notice] = l(:notice_successful_update)
        else
          flash[:error] = l(:error_empty_note)
        end
      end        
    end
    redirect_to :back    
  end
  
  def assign    
  end
  
  def assignment
    if params[:commit] == l(:button_submit)
      revision = DmsfFileRevision.find_by_id params[:dmsf_file_revision_id]
      if revision
        revision.set_workflow(params[:dmsf_workflow_id], params[:action])
        revision.assign_workflow(params[:dmsf_workflow_id])
        if request.post? 
          if revision.save
            file = DmsfFile.find_by_id revision.dmsf_file_id
            file.lock! if file
            flash[:notice] = l(:notice_successful_update)
          else
            flash[:error] = l(:error_workflow_assign)
          end
        end
      end    
    end
    redirect_to :back        
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
      flash[:notice] = l(:notice_successful_delete)
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
    render :layout => false
  end
  
  def add_step     
    if request.post?            
      users = User.find_all_by_id(params[:user_ids])      
      if params[:step] == '0'
        step = @workflow.dmsf_workflow_steps.collect{|s| s.step}.uniq.count + 1        
      else
        step = params[:step].to_i
      end
      operator = (params[:commit] == l(:dmsf_and)) ? DmsfWorkflowStep::OPERATOR_AND : DmsfWorkflowStep::OPERATOR_OR
      users.each do |user|        
        @workflow.dmsf_workflow_steps << DmsfWorkflowStep.new(
          :dmsf_workflow_id => @workflow.id, 
          :step => step, 
          :user_id => user.id, 
          :operator => operator)
      end         
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
          unless ws.save
            flash[:error] = l(:notice_cannot_renumber_steps)
          end
        end
      end      
    end        
    respond_to do |format|
      format.html      
    end
  end
  
  def reorder_steps    
    if request.put?
      unless @workflow.reorder_steps(params[:step].to_i, params[:workflow_step][:move_to])
        flash[:error] = l(:notice_cannot_renumber_steps)
      end     
    end        
    respond_to do |format|
      format.html      
    end
  end
  
  def start
    revision = DmsfFileRevision.find_by_id(params[:dmsf_file_revision_id])
    if revision      
      if request.post?        
        revision.set_workflow(@workflow.id, params[:action])
        if revision.save          
          assignments = @workflow.next_assignments revision.id          
          DmsfMailer.workflow_notification(
            assignments.collect{ |assignment| assignment.user.mail},
            @workflow, 
            revision,
            "Approval workflow #{@workflow.name} started",
            'been started and you are expected to do an approval in the current approval step',
            'To proceed click on the check box icon next to the document in').deliver
          flash[:notice] = l(:notice_workflow_started)
        else
          flash[:error] = l(:notice_cannot_start_workflow)
        end
      end
    end
    redirect_to :back
  end
    
private    
  def find_workflow   
    @workflow = DmsfWorkflow.find_by_id(params[:id])    
  end
    
  def find_project    
    if @workflow && @workflow.project
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
  
  def authorize_custom
    require_admin unless @project
  end
end