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

require File.expand_path('../../test_helper', __FILE__)

# Mailer tests
class DmsfMailerTest < RedmineDmsf::Test::UnitTest
  include Redmine::I18n

  fixtures :dmsf_workflows, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @file1.notify_activate
    @wf1 = DmsfWorkflow.find 1
    @rev2 = DmsfFileRevision.find 2
    # Mailer settings
    ActionMailer::Base.deliveries.clear
    Setting.plain_text_mail = '0'
    Setting.default_language = 'en'
    # Notification
    m1 = Member.find 1
    m1.dmsf_mail_notification = true
    m1.save
  end

  def test_files_updated
    DmsfMailer.deliver_files_updated(@file1.project, [@file1])
    email = last_email
    return unless email # Sometimes it doesn't work. Especially on localhost.

    body = text_part(email)&.body
    assert(body.include?(@file1.project.name)) if body
    body = html_part(email)&.body
    assert(body.include?(@file1.project.name)) if body
  end

  def test_files_deleted
    DmsfMailer.deliver_files_deleted(@file1.project, [@file1])
    email = last_email
    return unless email # Sometimes it doesn't work. Especially on localhost.

    body = text_part(email)&.body
    assert(body.include?(@file1.project.name)) if body
    body = html_part(email)&.body
    assert(body.include?(@file1.project.name)) if body
  end

  def test_files_downloaded
    DmsfMailer.deliver_files_downloaded(@file1.project, [@file1], '127.0.0.1')
    email = last_email
    return unless email # Sometimes it doesn't work. Especially on localhost.

    body = text_part(email)&.body
    assert(body.include?(@file1.project.name)) if body
    body = html_part(email)&.body
    assert(body.include?(@file1.project.name)) if body
  end

  def test_send_documents
    email_params = {}
    body = 'Test'
    email_params[:to] = @jsmith.mail
    email_params[:from] = @jsmith.mail
    email_params[:body] = body
    email_params[:links_only] = '1'
    email_params[:public_urls] = '0'
    email_params[:expired_at] = DateTime.current.to_s
    email_params[:folders] = nil
    email_params[:files] = "[\"#{@file1.id}\"]"
    DmsfMailer.deliver_send_documents(@file1.project, email_params, @jsmith)
    email = last_email
    return unless email # Sometimes it doesn't work. Especially on localhost.

    body = text_part(email)&.body
    assert(body.include?(body)) if body
    body = html_part(email)&.body
    assert(body.include?(body)) if body
  end

  def test_workflow_notification
    DmsfMailer.deliver_workflow_notification([@jsmith], @wf1, @rev2, :text_email_subject_started,
                                             :text_email_started, :text_email_to_proceed)
    email = last_email
    return unless email # Sometimes it doesn't work. Especially on localhost.

    body = text_part(email)&.body
    assert(body.include?(l(:text_email_subject_started))) if body
    body = html_part(email)&.body
    assert(body.include?(l(:text_email_subject_started))) if body
  end

  def test_get_notify_users
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      users = DmsfMailer.get_notify_users(@project1, @file1)
      assert users.present?
    end
    with_settings notified_events: [] do
      users = DmsfMailer.get_notify_users(@project1, @file1)
      assert users.empty?
    end
  end

  def test_get_notify_users_notification_switched_off
    @file1.notify_deactivate
    users = DmsfMailer.get_notify_users(@project1, @file1)
    assert users.blank?
  end

  def test_get_notify_users_on_inactive_projects
    @project1.status = Project::STATUS_CLOSED
    users = DmsfMailer.get_notify_users(@project1, @file1)
    assert users.blank?
  end

  def test_get_notify_users_with_watchers
    @file1.add_watcher @jsmith
    with_settings notified_events: [] do
      users = DmsfMailer.get_notify_users(@project1, @file1)
      assert users.present?
    end
  end
end
