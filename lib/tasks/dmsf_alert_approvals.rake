# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

desc <<~END_DESC
  Alert all users who are expected to do an approval in the current approval steps

  Available options:
    * dry_run - No email, just print list of recipients to the console

  Example:
    rake redmine:dmsf_alert_approvals RAILS_ENV="production"
    rake redmine:dmsf_alert_approvals dry_run=1 RAILS_ENV="production"
END_DESC

namespace :redmine do
  task dmsf_alert_approvals: :environment do
    DmsfAlertApprovals.alert
  end
end

# Alert approvals
class DmsfAlertApprovals
  def self.alert
    dry_run = ENV.fetch('dry_run', nil)
    revisions = DmsfFileRevision.visible.joins(:dmsf_file)
                                .joins('JOIN projects ON projects.id = dmsf_files.project_id')
                                .where(dmsf_file_revisions: { workflow: DmsfWorkflow::STATE_WAITING_FOR_APPROVAL },
                                       projects: { status: Project::STATUS_ACTIVE })
    revisions.each do |revision|
      next unless revision.dmsf_file.last_revision == revision

      workflow = DmsfWorkflow.find_by(id: revision.dmsf_workflow_id)
      next unless workflow

      assignments = workflow.next_assignments revision.id
      assignments.each do |assignment|
        next unless assignment.user.active?

        if dry_run
          $stdout.puts "#{assignment.user.name} <#{assignment.user.mail}>"
        else
          DmsfMailer.deliver_workflow_notification(
            [assignment.user],
            workflow,
            revision,
            :text_email_subject_requires_approval,
            :text_email_finished_step,
            :text_email_to_proceed,
            nil,
            assignment.dmsf_workflow_step
          )
        end
      end
    end
  end
end
