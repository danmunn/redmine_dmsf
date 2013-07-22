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

desc <<-END_DESC
Alert all users who are expected to do an approval in the current approval steps

Available options:

Example:
  rake redmine:dmsf_alert_approvals RAILS_ENV="production"
END_DESC
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")

class DmsfAlertApprovals
  
  def self.alert
    revisions = DmsfFileRevision.where(:workflow => 1)
    revisions.each do |revision|
      next unless revision.file.last_revision == revision
      workflow = DmsfWorkflow.find_by_id revision.dmsf_workflow_id
      next unless workflow
      assignments = workflow.next_assignments revision.id            
      DmsfMailer.workflow_notification(
        assignments.collect{|a| a.user.mail}, 
        workflow, 
        revision,
        "Approval workflow #{workflow.name} requires your approval",
        'finished one of the approval steps and you are expected to do an approval in the next approval step',
        'To proceed click on the check box icon next to the document in the').deliver
      Rails.logger.info "#{assignments.collect{|a| a.user.login}.join(',')} were alerted in order to do an approval of [workflow = #{workflow.id}, revision = #{revision.id}]"
    end
  end
end

namespace :redmine do
  task :dmsf_alert_approvals => :environment do    
    DmsfAlertApprovals.alert
  end
end
