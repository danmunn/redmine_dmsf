# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@lbcfree.net>
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

class DmsfMailerTest < RedmineDmsf::Test::UnitTest
  include Redmine::I18n

  fixtures :users, :projects, :dmsf_files, :dmsf_workflows, :dmsf_file_revisions, :members

  def setup
    @user2 = User.find_by_id 2
    @file1 = DmsfFile.find_by_id 1
    @wf1 = DmsfWorkflow.find_by_id 1
    @rev2 = DmsfFileRevision.find_by_id 2
    @project1 = Project.find_by_id 1
  end

  def test_truth
    assert_kind_of User, @user2
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFileRevision, @rev2
    assert_kind_of DmsfWorkflow, @wf1
    assert_kind_of Project, @project1
  end

  def test_files_updated
    email = DmsfMailer.files_updated(@user2, @file1.project, [@file1]).deliver
    assert email
    assert text_part(email).body.include? @file1.project.name
    assert html_part(email).body.include? @file1.project.name
  end

  def test_files_deleted
    email = DmsfMailer.files_deleted(@user2, @file1.project, [@file1]).deliver
    assert email
    assert text_part(email).body.include? @file1.project.name
    assert html_part(email).body.include? @file1.project.name
  end

  def test_send_documents
    email_params = Hash.new
    body = 'Test'
    email_params[:body] = body
    email_params[:links_only] = '1'
    email_params[:public_urls] == '0'
    email_params[:expired_at] = Date.today
    email_params[:folders] = nil
    email_params[:files] = "[\"#{@file1.id}\"]"
    email = DmsfMailer.send_documents(@file1.project, @user2, email_params).deliver
    assert email
    assert text_part(email).body.include? body
    assert html_part(email).body.include? body
  end

  def test_workflow_notification
    email = DmsfMailer.workflow_notification(@user2, @wf1, @rev2, :text_email_subject_started, :text_email_started,
                                             :text_email_to_proceed)
    assert email
    assert text_part(email).body.include? l(:text_email_subject_started)
    assert html_part(email).body.include? l(:text_email_subject_started)
  end

  def test_get_notify_users
    @file1.notification = true
    users = DmsfMailer.get_notify_users(@project1, [@file1])
    assert users.present?
  end

  def test_get_notify_users_notification_switched_off
    @file1.notification = false
    users = DmsfMailer.get_notify_users(@project1, [@file1])
    assert users.blank?
  end

  def test_get_notify_users_on_inactive_projects
    @file1.notification = true
    @project1.status = Project::STATUS_CLOSED
    users = DmsfMailer.get_notify_users(@project1, [@file1])
    assert users.blank?
  end

  private

  def text_part(email)
    email.parts.detect {|part| part.content_type.include?('text/plain')}
  end

  def html_part(email)
    email.parts.detect {|part| part.content_type.include?('text/html')}
  end

end