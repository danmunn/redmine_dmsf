# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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
  model_object DmsfWorkflow
    
  before_filter :find_model_object, :except => [:create, :new, :index, :assign, :assignment]    
  before_filter :find_project
  before_filter :authorize_custom
  
  layout :workflows_layout
  
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
            if @dmsf_workflow.try_finish revision, action, (params[:step_action].to_i / 10)            
              file = DmsfFile.joins(:revisions).where(:dmsf_file_revisions => {:id => revision.id}).first
              if file
                begin
                  file.unlock!
                rescue DmsfLockError => e
                  logger.warn e.message
                end
              end              
              if revision.workflow == DmsfWorkflow::STATE_APPROVED
                # Just approved
                recipients = revision.file.project.members.collect{ |m| m.user }
                if User.current && User.current.logged? && User.current.pref.no_self_notified
                  recipients.delete User.current
                end
                recipients.each do |user|
                  DmsfMailer.workflow_notification(
                    user,
                    @dmsf_workflow, 
                    revision,
                    :text_email_subject_approved,
                    :text_email_finished_approved,
                    :text_email_to_see_history).deliver if user
                end
                if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
                  recipients = revision.file.project.members.collect{ |m| m.user }
                  if User.current && User.current.logged? && User.current.pref.no_self_notified
                    recipients.delete User.current
                  end
                  unless recipients.empty?
                    to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                    to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                    flash[:warning] = l(:warning_email_notifications, :to => to)
                  end
                end
              else
                # Just rejected                
                recipients = @dmsf_workflow.participiants
                recipients.push User.find_by_id revision.dmsf_workflow_assigned_by
                recipients.uniq!
                if User.current && User.current.logged? && User.current.pref.no_self_notified
                  recipients.delete User.current
                end
                recipients.each do |user|
                  DmsfMailer.workflow_notification(
                    user, 
                    @dmsf_workflow, 
                    revision,
                    :text_email_subject_rejected,
                    :text_email_finished_rejected,
                    :text_email_to_see_history,
                    action.note).deliver if user
                end
                if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
                  unless recipients.empty?
                    to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                    to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                    flash[:warning] = l(:warning_email_notifications, :to => to)
                  end
                end
              end
            else
              if action.action == DmsfWorkflowStepAction::ACTION_DELEGATE
                # Delegation                
                delegate = User.find_by_id params[:step_action].to_i / 10
                if delegate
                  DmsfMailer.workflow_notification(
                    delegate, 
                    @dmsf_workflow, 
                    revision,
                    :text_email_subject_delegated,
                    :text_email_finished_delegated,
                    :text_email_to_proceed,
                    action.note).deliver
                  if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
                    flash[:warning] = l(:warning_email_notifications, :to => delegate.name)                    
                  end
                end
              else
                # Next step
                assignments = @dmsf_workflow.next_assignments revision.id
                unless assignments.empty?
                  if assignments.first.dmsf_workflow_step.step != action.dmsf_workflow_step_assignment.dmsf_workflow_step.step
                    # Next step
                    assignments.each do |assignment|
                      DmsfMailer.workflow_notification(
                        assignment.user, 
                        @dmsf_workflow, 
                        revision,
                        :text_email_subject_requires_approval,
                        :text_email_finished_step,
                        :text_email_to_proceed).deliver if assignment.user
                    end
                    to = User.find_by_id revision.dmsf_workflow_assigned_by                    
                    DmsfMailer.workflow_notification(
                      to, 
                      @dmsf_workflow, 
                      revision,
                      :text_email_subject_updated,
                      :text_email_finished_step_short,
                      :text_email_to_see_status).deliver if to
                    if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
                      recipients = assignments.collect{ |a| a.user }
                      recipients << to if to && !recipients.include?(to)
                      unless recipients.empty?
                        to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                        to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                        flash[:warning] = l(:warning_email_notifications, :to => to)
                      end
                    end
                  end                  
                end
              end
            end
          end
          flash[:notice] = l(:notice_successful_update)
        elsif action.action != DmsfWorkflowStepAction::ACTION_APPROVE && action.note.blank?
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
        if params[:dmsf_workflow_id].present?
          revision.assign_workflow(params[:dmsf_workflow_id])
          if request.post? 
            if revision.save
              file = DmsfFile.find_by_id revision.dmsf_file_id
              if file
                begin
                  file.lock!
                rescue DmsfLockError => e
                  logger.warn e.message
                end
                flash[:notice] = l(:notice_successful_update)                
              end
            else
              flash[:error] = l(:error_workflow_assign)
            end
          end
        end
      end    
    end
    redirect_to :back        
  end

  def log
  end
  
  def new   
    @dmsf_workflow = DmsfWorkflow.new        
  end
  
  def create
    @dmsf_workflow = DmsfWorkflow.new(:name => params[:name], :project_id => params[:project_id])
    if request.post? && @dmsf_workflow.save
      flash[:notice] = l(:notice_successful_create)
      if @project
        redirect_to settings_project_path(@project, :tab => 'dmsf_workflow')
      else
        redirect_to dmsf_workflows_path
      end
    else      
      render :action => 'new'
    end
  end
  
  def update    
    if request.put? && @dmsf_workflow.update_attributes({:name => params[:name]})
      flash[:notice] = l(:notice_successful_update)
      if @project
        redirect_to settings_project_path(@project, :tab => 'dmsf_workflow')
      else
        redirect_to dmsf_workflows_path
      end    
    else      
      render :action => 'edit'
    end
  end
  
  def destroy    
    begin
      @dmsf_workflow.destroy 
      flash[:notice] = l(:notice_successful_delete)
    rescue
      flash[:error] = l(:error_unable_delete_dmsf_workflow)
    end
    if @project
      redirect_to settings_project_path(@project, :tab => 'dmsf_workflow')
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
        step = @dmsf_workflow.dmsf_workflow_steps.collect{|s| s.step}.uniq.count + 1        
      else
        step = params[:step].to_i
      end
      operator = (params[:commit] == l(:dmsf_and)) ? DmsfWorkflowStep::OPERATOR_AND : DmsfWorkflowStep::OPERATOR_OR
      users.each do |user|        
        @dmsf_workflow.dmsf_workflow_steps << DmsfWorkflowStep.new(
          :dmsf_workflow_id => @dmsf_workflow.id, 
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
      DmsfWorkflowStep.where(:dmsf_workflow_id => @dmsf_workflow.id, :step => params[:step]).each do |ws|
        @dmsf_workflow.dmsf_workflow_steps.delete(ws)
      end                    
      @dmsf_workflow.dmsf_workflow_steps.each do |ws|
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
      unless @dmsf_workflow.reorder_steps(params[:step].to_i, params[:workflow_step][:move_to])
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
      revision.set_workflow(@dmsf_workflow.id, params[:action])
      if revision.save          
        assignments = @dmsf_workflow.next_assignments revision.id          
        assignments.each do |assignment|
          DmsfMailer.workflow_notification(
            assignment.user,
            @dmsf_workflow, 
            revision,
            :text_email_subject_started,
            :text_email_started,
            :text_email_to_proceed).deliver if assignment.user
        end
        if Setting.plugin_redmine_dmsf[:dmsf_display_notified_recipients] == '1'
          recipients = assignments.collect { |a| a.user }
          recipients.uniq!
          if User.current && User.current.logged? && User.current.pref.no_self_notified
            recipients.delete User.current
          end
          unless recipients.empty?
            to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
            to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
            flash[:warning] = l(:warning_email_notifications, :to => to)
          end
        end
        flash[:notice] = l(:notice_workflow_started)
      else
        flash[:error] = l(:notice_cannot_start_workflow)
      end      
    end
    redirect_to :back
  end
    
private    

  def find_project    
    if @dmsf_workflow
      if @dmsf_workflow.project # Project workflow
        @project = @dmsf_workflow.project
      else # Global workflow
        revision = DmsfFileRevision.find_by_id params[:dmsf_file_revision_id]
        @project = revision.project if revision
      end
    else
      if params[:project_id].present?
        @project = Project.find_by_id params[:project_id]
      else
        @project = Project.find_by_identifier params[:id]
      end
    end    
  end
  
  def workflows_layout    
    @project ? 'base' : 'admin'
  end    
  
  def authorize_custom    
    if @project
      authorize
    else
      require_admin
    end
  end
end