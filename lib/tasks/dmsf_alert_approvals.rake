# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-14   Karel Picman <karel.picman@kontron.com>
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

desc <<-END_DESC
Alert all users who are expected to do an approval in the current approval steps

Available options:

Example:
  rake redmine:dmsf_alert_approvals RAILS_ENV="production"
END_DESC
  
namespace :redmine do
  task :dmsf_alert_approvals => :environment do    
    DmsfAlertApprovals.alert
  end
end

class DmsfAlertApprovals    

  def self.alert
    revisions = DmsfFileRevision.where(:workflow => DmsfWorkflow::STATE_WAITING_FOR_APPROVAL)
    revisions.each do |revision|
      next unless revision.file.last_revision == revision
      workflow = DmsfWorkflow.find_by_id revision.dmsf_workflow_id
      next unless workflow
      assignments = workflow.next_assignments revision.id
      assignments.each do |assignment|
        DmsfMailer.workflow_notification(
          assignment.user, 
          workflow, 
          revision,
          :text_email_subject_requires_approval,
          :text_email_finished_step,
          :text_email_to_proceed).deliver
      end      
    end
  end

end