# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Workflow
class DmsfWorkflow < ApplicationRecord
  has_many :dmsf_workflow_steps, -> { order(step: :asc) }, dependent: :destroy, inverse_of: :dmsf_workflow
  belongs_to :author, class_name: 'User'

  scope :sorted, -> { order name: :asc }
  scope :global, -> { where project_id: nil }
  scope :active, -> { where status: STATUS_ACTIVE }
  scope :status, ->(arg) { where arg.blank? ? nil : { status: arg.to_i } }

  validates :name, presence: true, length: { maximum: 255 }, dmsf_workflow_name: true

  STATE_ASSIGNED = 3
  STATE_WAITING_FOR_APPROVAL = 1
  STATE_APPROVED = 2
  STATE_REJECTED = 4
  STATE_OBSOLETE = 5

  STATUS_LOCKED = 0
  STATUS_ACTIVE = 1

  def self.workflow_str(workflow)
    case workflow
    when STATE_WAITING_FOR_APPROVAL
      l(:title_waiting_for_approval)
    when STATE_APPROVED
      l(:title_approved)
    when STATE_ASSIGNED
      l(:title_assigned)
    when STATE_REJECTED
      l(:title_rejected)
    when DmsfWorkflow::STATE_OBSOLETE
      l(:title_obsolete)
    end
  end

  def self.workflow_info(workflow, workflow_id, revision_id)
    text = ''
    names = ''
    if workflow.to_i == STATE_WAITING_FOR_APPROVAL
      dmsf_workflow = DmsfWorkflow.find_by(id: workflow_id)
      if dmsf_workflow
        assignments = dmsf_workflow.next_assignments(revision_id)
        if assignments.any?
          user_ids = assignments.map(&:user_id)
          names = User.where(id: user_ids).all.map(&:name).join(',')
          workflow_step_id = assignments.first[:dmsf_workflow_step_id]
          if workflow_step_id
            step = DmsfWorkflowStep.find_by(id: workflow_step_id)
            text = step.name if step&.name.present?
          end
        end
      end
    end
    text = DmsfWorkflow.workflow_str(workflow.to_i) if text.blank?
    [text, names]
  end

  def participiants
    users = []
    dmsf_workflow_steps.each do |step|
      users << step.user unless users.include? step.user
    end
    users
  end

  def self.workflows(project)
    where(project_id: project)
  end

  def project
    Project.find_by(id: project_id) if project_id
  end

  def to_s
    name
  end

  def reorder_steps(step, move_to)
    DmsfWorkflow.transaction do
      dmsf_workflow_steps.each do |ws|
        if ws.step == step
          ws.update_attribute :step, move_to
        elsif ws.step >= move_to && ws.step < step
          # Move up
          ws.update_attribute :step, ws.step + 1
        elsif ws.step <= move_to && ws.step > step
          # Move down
          ws.update_attribute :step, ws.step - 1
        end
      end
    end
    true
  end

  def delegates(query, dmsf_workflow_step_assignment_id, dmsf_file_revision_id)
    sql = if dmsf_workflow_step_assignment_id && dmsf_file_revision_id
            [
              %(id NOT IN (SELECT a.user_id FROM dmsf_workflow_step_assignments a WHERE id = ?)
                AND id IN (SELECT m.user_id FROM members m JOIN dmsf_files f ON f.project_id = m.project_id
                JOIN dmsf_file_revisions r ON r.dmsf_file_id = f.id WHERE r.id = ?)),
              dmsf_workflow_step_assignment_id, dmsf_file_revision_id
            ]
          elsif project
            ['id IN (SELECT user_id FROM members WHERE project_id = ?)', project.id]
          else
            '1=1'
          end

    if query.present?
      User.active.sorted.where(sql).like query
    else
      User.active.sorted.where sql
    end
  end

  def next_assignments(dmsf_file_revision_id)
    results = []
    nsteps = dmsf_workflow_steps.collect(&:step).uniq
    nsteps.each do |i|
      step_is_finished = false
      steps = dmsf_workflow_steps.filter_map { |s| s.step == i ? s : nil }
      steps.each do |step|
        step.dmsf_workflow_step_assignments.where(dmsf_file_revision_id: dmsf_file_revision_id)
            .find_each do |assignment|
          assignment.dmsf_workflow_step_actions.find_each do |action|
            case action.action
            when DmsfWorkflowStepAction::ACTION_APPROVE
              step_is_finished = true
              # Try to find another unfinished AND step
              exists = false
              stps = dmsf_workflow_steps
                     .filter_map { |s| s.step == i && s.operator == DmsfWorkflowStep::OPERATOR_AND ? s : nil }
              stps.each do |s|
                s.dmsf_workflow_step_assignments.where(dmsf_file_revision_id: dmsf_file_revision_id).find_each do |a|
                  exists = a.add?(dmsf_file_revision_id)
                  break if exists
                end
                break if exists
              end
              step_is_finished = false if exists
              break
            when DmsfWorkflowStepAction::ACTION_REJECT
              return []
            end
          end
          break if step_is_finished
        end
        break if step_is_finished
      end
      next if step_is_finished

      steps.each do |step|
        step.dmsf_workflow_step_assignments.where(dmsf_file_revision_id: dmsf_file_revision_id)
            .find_each do |assignment|
          results << assignment if assignment.add?(dmsf_file_revision_id)
        end
      end
      return results
    end
    results
  end

  def assign(dmsf_file_revision_id)
    dmsf_workflow_steps.each do |ws|
      ws.assign(dmsf_file_revision_id)
    end
  end

  def try_finish(revision, action, user_id)
    case action.action
    when DmsfWorkflowStepAction::ACTION_APPROVE
      assignments = next_assignments(revision.id)
      return false unless assignments.empty?

      revision.workflow = DmsfWorkflow::STATE_APPROVED
      revision.save!
      return true
    when DmsfWorkflowStepAction::ACTION_REJECT
      revision.workflow = DmsfWorkflow::STATE_REJECTED
      revision.save!
      return true
    when DmsfWorkflowStepAction::ACTION_DELEGATE
      dmsf_workflow_steps.each do |step|
        step.dmsf_workflow_step_assignments.each do |assignment|
          next unless assignment.id == action.dmsf_workflow_step_assignment_id

          assignment.user_id = user_id
          assignment.save!
          return false
        end
      end
    end
    false
  end

  def copy_to(project, name = nil)
    new_wf = dup
    new_wf.name = name if name
    new_wf.project_id = project ? project.id : nil
    new_wf.author = User.current
    if new_wf.save
      dmsf_workflow_steps.each do |step|
        step.copy_to(new_wf)
      end
    end
    new_wf
  end

  def locked?
    status == STATUS_LOCKED
  end

  def active?
    status == STATUS_ACTIVE
  end

  def notify_users(project, revision, controller)
    assignments = next_assignments(revision.id)
    recipients = assignments.collect(&:user).uniq
    recipients &= DmsfMailer.get_notify_users(project, revision.dmsf_file, force_notification: true)
    DmsfMailer.deliver_workflow_notification(
      recipients,
      self,
      revision,
      :text_email_subject_started,
      :text_email_started,
      :text_email_to_proceed,
      nil,
      assignments.first&.dmsf_workflow_step
    )
    return unless Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] && controller && recipients.present?

    max_recipients = Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i
    to = recipients.collect(&:name).first(max_recipients).join(', ')
    return if to.blank?

    to << (recipients.count > max_recipients.to_i ? ',...' : '.')
    controller.flash[:warning] = l(:warning_email_notifications, to: to) if controller
  end
end
