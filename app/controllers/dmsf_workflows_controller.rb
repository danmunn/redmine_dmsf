# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

  model_object DmsfWorkflow
  menu_item :dmsf_approvalworkflows

  before_action :find_model_object, except: [:create, :new, :index, :assign, :assignment]
  before_action :find_project
  before_action :authorize_custom
  before_action :permissions, only: [:new_action, :assignment, :start]
  before_action :approver_candidates, only: [:remove_step, :show, :reorder_steps, :add_step]

  layout :workflows_layout

  def permissions
    revision = DmsfFileRevision.find_by(id: params[:dmsf_file_revision_id]) if params[:dmsf_file_revision_id].present?
    if revision
      render_403 unless revision.dmsf_file || DmsfFolder.permissions?(revision.dmsf_file.dmsf_folder)
    end
    true
  end

  def initialize
    @dmsf_workflow = nil
    @project = nil
    super
  end

  def index
    @status = params[:status] || 1
    @workflow_pages, @workflows = paginate DmsfWorkflow.status(@status).global.sorted, per_page: 25
  end

  def action
  end

  def new_action
    if params[:commit] == l(:button_submit)
      action = DmsfWorkflowStepAction.new(
        dmsf_workflow_step_assignment_id: params[:dmsf_workflow_step_assignment_id],
        action: (params[:step_action].to_i >= 10) ? DmsfWorkflowStepAction::ACTION_DELEGATE : params[:step_action],
        note: params[:note])
      if request.post?
        if action.save
          revision = DmsfFileRevision.find_by(id: params[:dmsf_file_revision_id])
          if revision
            if @dmsf_workflow.try_finish revision, action, (params[:step_action].to_i / 10)
              if revision.dmsf_file
                begin
                  revision.dmsf_file.unlock!(true) unless Setting.plugin_redmine_dmsf['dmsf_keep_documents_locked']
                rescue DmsfLockError => e
                  flash[:info] = e.message
                end
              end
              if revision.workflow == DmsfWorkflow::STATE_APPROVED
                # Just approved
                recipients = DmsfMailer.get_notify_users(@project, [revision.dmsf_file], true)
                DmsfMailer.deliver_workflow_notification(
                    recipients,
                    @dmsf_workflow,
                    revision,
                    :text_email_subject_approved,
                    :text_email_finished_approved,
                    :text_email_to_see_history)
                if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
                  unless recipients.blank?
                    to = recipients.collect{ |r| h(r.name) }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                    to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                    flash[:warning] = l(:warning_email_notifications, to: to)
                  end
                end
              else
                # Just rejected
                recipients = @dmsf_workflow.participiants
                recipients.push revision.dmsf_workflow_assigned_by_user
                recipients.uniq!
                recipients = recipients & DmsfMailer.get_notify_users(@project, [revision.dmsf_file], true)
                DmsfMailer.deliver_workflow_notification(
                    recipients,
                    @dmsf_workflow,
                    revision,
                    :text_email_subject_rejected,
                    :text_email_finished_rejected,
                    :text_email_to_see_history,
                    action.note)
                if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
                  unless recipients.blank?
                    to = recipients.collect{ |r| h(r.name) }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                    to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                    flash[:warning] = l(:warning_email_notifications, to: to)
                  end
                end
              end
            else
              if action.action == DmsfWorkflowStepAction::ACTION_DELEGATE
                # Delegation
                delegate = User.active.find_by(id: params[:step_action].to_i / 10)
                if DmsfMailer.get_notify_users(@project, [revision.dmsf_file], true).include?(delegate)
                  DmsfMailer.deliver_workflow_notification(
                    [delegate],
                    @dmsf_workflow,
                    revision,
                    :text_email_subject_delegated,
                    :text_email_finished_delegated,
                    :text_email_to_proceed,
                    action.note,
                    action.dmsf_workflow_step_assignment.dmsf_workflow_step)
                  if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
                    flash[:warning] = l(:warning_email_notifications, to: h(delegate.name))
                  end
                end
              else
                # Next step
                assignments = @dmsf_workflow.next_assignments revision.id
                unless assignments.empty?
                  if assignments.first.dmsf_workflow_step.step != action.dmsf_workflow_step_assignment.dmsf_workflow_step.step
                    # Next step
                    assignments.each do |assignment|
                      if assignment.user && DmsfMailer.get_notify_users(@project, [revision.dmsf_file], true).include?(assignment.user)
                        DmsfMailer.deliver_workflow_notification(
                          [assignment.user],
                          @dmsf_workflow,
                          revision,
                          :text_email_subject_requires_approval,
                          :text_email_finished_step,
                          :text_email_to_proceed,
                          nil,
                          assignment.dmsf_workflow_step)
                      end
                    end
                    to = revision.dmsf_workflow_assigned_by_user
                    if to && DmsfMailer.get_notify_users(@project, [revision.dmsf_file], true).include?(to)
                      DmsfMailer.deliver_workflow_notification(
                        [to],
                        @dmsf_workflow,
                        revision,
                        :text_email_subject_updated,
                        :text_email_finished_step_short,
                        :text_email_to_see_status)
                    end
                    if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
                      recipients = assignments.collect{ |a| a.user }
                      recipients << to if to
                      recipients.uniq!
                      recipients = recipients & DmsfMailer.get_notify_users(@project, [revision.dmsf_file], true)
                      unless recipients.empty?
                        to = recipients.collect{ |r| h(r.name) }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
                        to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
                        flash[:warning] = l(:warning_email_notifications, to: to)
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
    redirect_back_or_default dmsf_folder_path(id: @project.id, folder_id: @folder)
  end

  def assign
  end

  def assignment
    if (params[:commit] == l(:button_submit)) &&
        params[:dmsf_workflow_id].present? && (params[:dmsf_workflow_id] != '-1')
      # DMS file
      if params[:dmsf_file_revision_id].present? && params[:dmsf_link_id].blank? && params[:attachment_id].blank?
        revision = DmsfFileRevision.find_by(id: params[:dmsf_file_revision_id])
        begin
          if revision
            revision.set_workflow(params[:dmsf_workflow_id], params[:action])
            revision.assign_workflow(params[:dmsf_workflow_id])
            if request.post?
              if revision.save
                file = DmsfFile.find_by(id: revision.dmsf_file_id)
                if file
                  begin
                    file.lock!
                  rescue DmsfLockError => e
                    Rails.logger.warn e.message
                  end
                  flash[:notice] = l(:notice_successful_update)
                end
              else
                flash[:error] = l(:error_workflow_assign)
              end
            end
          end
        rescue => e
          flash[:error] = e.message
        end
        redirect_back_or_default dmsf_folder_path(id: @project.id, folder_id: @folder)
        return
      # DMS link (attached)
      elsif params[:dmsf_link_id].present?
        @dmsf_link_id = params[:dmsf_link_id]
        @dmsf_workflow_id = params[:dmsf_workflow_id]
      # Attachment (attached)
      elsif params[:attachment_id].present?
        @attachment_id = params[:attachment_id]
        @dmsf_workflow_id = params[:dmsf_workflow_id]
      end
     else
      redirect_back_or_default dmsf_folder_path(id: @project.id, folder_id: @folder)
      return
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def log
    if params[:dmsf_file_revision_id].present?
      @revision = DmsfFileRevision.find_by(id: params[:dmsf_file_revision_id])
    elsif params[:dmsf_file_id].present?
      dmsf_file = DmsfFile.find_by(id: params[:dmsf_file_id])
      @revision = dmsf_file.last_revision if dmsf_file
    elsif params[:dmsf_link_id].present?
      dmsf_link = DmsfLink.find_by(id: params[:dmsf_link_id])
      if dmsf_link
        dmsf_file = dmsf_link.target_file
        @revision = dmsf_file.last_revision
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    redirect_to dmsf_workflow_path(@dmsf_workflow)
  end

  def new
    @dmsf_workflow = DmsfWorkflow.new

    # Reload
    if params[:dmsf_workflow] && params[:dmsf_workflow][:name].present?
      @dmsf_workflow.name = params[:dmsf_workflow][:name]
    elsif params[:dmsf_workflow] && params[:dmsf_workflow][:id].present?
      names = DmsfWorkflow.where(id: params[:dmsf_workflow][:id]).pluck(:name)
      @dmsf_workflow.name = names.first
    end

    render layout: !request.xhr?
  end

  def create
    if params[:dmsf_workflow]
      if params[:dmsf_workflow][:id].to_i > 0
        wf = DmsfWorkflow.find_by(id: params[:dmsf_workflow][:id])
        @dmsf_workflow = wf.copy_to(@project, params[:dmsf_workflow][:name]) if wf
      else
        @dmsf_workflow = DmsfWorkflow.new
        @dmsf_workflow.name = params[:dmsf_workflow][:name]
        @dmsf_workflow.project_id = @project.id if @project
        @dmsf_workflow.author = User.current
        @dmsf_workflow.save
      end
    end
    if request.post? && @dmsf_workflow && @dmsf_workflow.valid?
      flash[:notice] = l(:notice_successful_create)
      if @project
        redirect_to settings_project_path(@project, tab: 'dmsf_workflow')
      else
        redirect_to dmsf_workflows_path
      end
    else
      render action: 'new'
    end
  end

  def update
    if params[:dmsf_workflow]
      res = @dmsf_workflow.update_attributes({ name: params[:dmsf_workflow][:name] }) if params[:dmsf_workflow][:name].present?
      res = @dmsf_workflow.update_attributes({ status: params[:dmsf_workflow][:status] }) if params[:dmsf_workflow][:status].present?
      if res
        flash[:notice] = l(:notice_successful_update)
        if @project
          redirect_to settings_project_path(@project, tab: 'dmsf_workflow')
        else
          redirect_to dmsf_workflows_path
        end
      else
        flash[:error] = @dmsf_workflow.errors.full_messages.to_sentence
        redirect_to dmsf_workflow_path(@dmsf_workflow)
      end
    else
      redirect_to dmsf_workflow_path(@dmsf_workflow)
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
      redirect_to settings_project_path(@project, tab: 'dmsf_workflow')
    else
      redirect_to dmsf_workflows_path
    end
  end

  def autocomplete_for_user
     respond_to do |format|
       format.js
     end
  end

  def new_step
    @steps = @dmsf_workflow.dmsf_workflow_steps.select('step, MAX(name) AS name').group(:step, :operator)

    respond_to do |format|
      format.html
      format.js
    end
  end

  def add_step
    if request.post?
      if params[:step] == '0'
        step = @dmsf_workflow.dmsf_workflow_steps.collect{|s| s.step}.uniq.count + 1
      else
        step = params[:step].to_i
      end
      operator = (params[:commit] == l(:dmsf_and)) ? DmsfWorkflowStep::OPERATOR_AND : DmsfWorkflowStep::OPERATOR_OR
      user_ids = User.where(id: params[:user_ids]).ids
      if user_ids.any?
        user_ids.each do |user_id|
          ws = DmsfWorkflowStep.new
          ws.dmsf_workflow_id = @dmsf_workflow.id
          ws.step = step
          ws.user_id = user_id
          ws.operator = operator
          ws.name = params[:name]
          if ws.save
            @dmsf_workflow.dmsf_workflow_steps << ws
          else
            flash[:error] = ws.errors.full_messages.to_sentence
          end
        end
      else
        flash[:error] = l(:error_workflow_assign)
      end
    end
    respond_to do |format|
      format.html
    end
  end

  def remove_step
    if request.delete?
      DmsfWorkflowStep.where(dmsf_workflow_id: @dmsf_workflow.id, step: params[:step]).find_each do |ws|
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
    redirect_back_or_default dmsf_workflow_path(@dmsf_workflow)
  end

  def reorder_steps
    if request.put?
      unless @dmsf_workflow.reorder_steps(params[:step].to_i, params[:dmsf_workflow][:position].to_i)
        flash[:error] = l(:notice_cannot_renumber_steps)
      end
    end
    respond_to do |format|
      format.html
      format.js {
        render inline: "location.replace('#{dmsf_workflow_path(@dmsf_workflow)}');"
      }
    end
  end

  def start
    revision = DmsfFileRevision.find_by(id: params[:dmsf_file_revision_id])
    if revision
      revision.set_workflow(@dmsf_workflow.id, params[:action])
      if revision.save
        @dmsf_workflow.notify_users(@project, revision, self)
        flash[:notice] = l(:notice_workflow_started)
      else
        flash[:error] = l(:notice_cannot_start_workflow)
      end
    end
    redirect_back_or_default dmsf_folder_path(id: @project.id, folder_id: @folder)
  end

  def update_step
    # Name
    if params[:dmsf_workflow].present?
      index = params[:step].to_i
      step = @dmsf_workflow.dmsf_workflow_steps[index]
      step.name = params[:dmsf_workflow][:step_name]
      if step.save
        @dmsf_workflow.dmsf_workflow_steps.where(step: step.step).find_each do |s|
          s.name = step.name
          unless s.save
            flash[:error] = s.errors.full_messages.to_sentence
          end
        end
      else
        flash[:error] = step.errors.full_messages.to_sentence
      end
    end
    # Operators/Assignees
    if params[:operator_step].present?
      params[:operator_step].each do |id, operator|
        step = DmsfWorkflowStep.find_by(id: id)
        if step
          step.operator = operator.to_i
          step.user_id = params[:assignee][id]
          unless step.save
            flash[:error] = step.errors.full_messages.to_sentence
            Rails.logger.error step.errors.full_messages.to_sentence
          end
        end
      end
    end
    redirect_to dmsf_workflow_path(@dmsf_workflow)
  end

  def delete_step
    step = DmsfWorkflowStep.find_by(id: params[:step])
    if step
      # Safe the name
      if step.name.present?
        @dmsf_workflow.dmsf_workflow_steps.each do |s|
          if s.step == step.step
            s.name = step.name
            s.save!
          end
        end
      end
      # Destroy
      step.destroy
    end
    redirect_to dmsf_workflow_path(@dmsf_workflow)
  end

private

  def find_project
    if @dmsf_workflow
      if @dmsf_workflow.project # Project workflow
        @project = @dmsf_workflow.project
      else # Global workflow
        if params[:dmsf_file_revision_id].present?
          revision = DmsfFileRevision.find_by(id: params[:dmsf_file_revision_id])
          @project = revision.dmsf_file.project if revision && revision.dmsf_file
        else
          @project = Project.find params[:project_id] if params[:project_id].present?
        end
      end
    else
      if params[:dmsf_workflow].present?
        @project = Project.find params[:dmsf_workflow][:project_id]
      elsif params[:project_id].present?
        @project = Project.find params[:project_id]
      else
        @project = Project.find(params[:id]) if params[:id].present?
      end
    end
  rescue ActiveRecord::RecordNotFound
    @project = nil
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

  def approver_candidates
    @approving_candidates = @project ? @project.users.to_a : User.active.to_a
  end

end
