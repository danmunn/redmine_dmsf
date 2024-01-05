# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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

require 'mailer'

# Mailer
class DmsfMailer < Mailer
  layout 'mailer'

  def self.deliver_files_updated(project, files)
    hash = {}
    files.each do |file|
      users = get_notify_users(project, file)
      users.each do |user|
        (hash[user] ||= []) << file
      end
    end
    hash.each do |user, docs|
      files_updated(user, project, docs).deliver_later
    end
  end

  def files_updated(user, project, files)
    redmine_headers 'Project' => project.identifier if project
    @files = files
    @project = project
    @author = files.first.last_revision.user if files.first.last_revision
    @author ||= User.anonymous
    message_id project
    set_language_if_valid user.language
    mail to: user, subject: "[#{@project.name} - #{l(:menu_dmsf)}] #{l(:text_email_doc_updated_subject)}"
  end

  def self.deliver_files_deleted(project, files)
    hash = {}
    files.each do |file|
      users = get_notify_users(project, file)
      users.each do |user|
        (hash[user] ||= []) << file
      end
    end
    hash.each do |user, docs|
      files_deleted(user, project, docs).deliver_later
    end
  end

  def files_deleted(user, project, files)
    redmine_headers 'Project' => project.identifier if project
    @files = files
    @project = project
    @author = files.first.deleted_by_user
    @author ||= User.anonymous
    message_id project
    set_language_if_valid user.language
    mail to: user, subject: "[#{@project.name} - #{l(:menu_dmsf)}] #{l(:text_email_doc_deleted_subject)}"
  end

  def self.deliver_files_downloaded(project, files, remote_ip)
    hash = {}
    files.each do |file|
      users = get_notify_users(project, file)
      users.each do |user|
        (hash[user] ||= []) << file if user.pref.receive_download_notification == '1'
      end
    end
    hash.each do |user, docs|
      files_downloaded(user, project, docs, remote_ip).deliver_later
    end
  end

  def files_downloaded(user, project, files, remote_ip)
    redmine_headers 'Project' => project.identifier if project
    @files = files
    @project = project
    @author = User.current
    @remote_ip = remote_ip
    message_id project
    set_language_if_valid user.language
    mail to: user, subject: "[#{@project.name} - #{l(:menu_dmsf)}] #{l(:text_email_doc_downloaded_subject)}"
  end

  def self.deliver_send_documents(project, email_params, author)
    send_documents(User.current, project, email_params, author).deliver_now
  end

  def send_documents(_, project, email_params, author)
    redmine_headers 'Project' => project.identifier if project
    @body = email_params[:body]
    @links_only = email_params[:links_only] == '1'
    @public_urls = email_params[:public_urls] == '1'
    @expired_at = email_params[:expired_at]
    @folders = email_params[:folders]
    @files = email_params[:files]
    @author = author
    unless @links_only
      if File.exist?(email_params[:zipped_content])
        zipped_content_data = File.binread(email_params[:zipped_content])
        attachments['Documents.zip'] = { content_type: 'application/zip', content: zipped_content_data }
      else
        Rails.logger.error "Cannot attach #{email_params[:zipped_content]}, it doesn't exist."
      end
    end
    skip_no_self_notified = false
    begin
      # We need to switch off no_self_notified temporarily otherwise the email won't be sent
      if (author == User.current) && author.pref.no_self_notified
        author.pref.no_self_notified = false
        skip_no_self_notified = true
      end
      res = mail(to: email_params[:to], cc: email_params[:cc], subject: email_params[:subject],
                 'From' => email_params[:from], 'Reply-To' => email_params[:reply_to])
    ensure
      author.pref.no_self_notified = true if skip_no_self_notified
    end
    res
  end

  def self.deliver_workflow_notification(users, workflow, revision, subject_id, text1_id, text2_id, notice = nil,
                                         step = nil)
    step_name = step&.name.present? ? step.name : step&.step
    users.each do |user|
      workflow_notification(user, workflow, revision, subject_id.to_s, text1_id.to_s, text2_id.to_s, notice,
                            step_name).deliver_now
    end
  end

  def workflow_notification(user, workflow, revision, subject_id, text1_id, text2_id, notice, step_name)
    return unless user && workflow && revision

    if revision.dmsf_file&.project
      @project = revision.dmsf_file.project
      redmine_headers 'Project' => @project.identifier
    end
    set_language_if_valid user.language
    @user = user
    message_id workflow
    @workflow = workflow
    @revision = revision
    @text1 = l(text1_id, name: workflow.name, filename: revision.dmsf_file.name, notice: notice, stepname: step_name)
    @text2 = l(text2_id)
    @notice = notice
    @author = revision.dmsf_workflow_assigned_by_user
    @author ||= User.anonymous
    mail to: user,
         subject:
           "[#{@project.name} - #{l(:field_label_dmsf_workflow)}] #{@workflow.name} #{l(subject_id)} #{step_name}"
  end

  # force_notification = true => approval workflow's notifications
  def self.get_notify_users(project, file, force_notification: false)
    return [] unless project.active?

    # Notifications
    if (force_notification && Setting.notified_events.include?('dmsf_workflow_plural')) ||
       (Setting.notified_events.include?('dmsf_legacy_notifications') && file&.notify?)
      notify_members = project.members.active.select do |notify_member|
        notify_user = notify_member.user
        if notify_user == User.current && notify_user.pref.no_self_notified
          false
        elsif notify_member.dmsf_mail_notification.nil?
          case notify_user.mail_notification
          when 'all'
            true
          when 'selected'
            notify_member.mail_notification?
          when 'only_my_events'
            file.involved?(notify_user) || file.assigned?(notify_user)
          when 'only_owner'
            file.owner? notify_user
          when 'only_assigned'
            file.assigned? notify_user
          else
            false
          end
        else
          notify_member.dmsf_mail_notification
        end
      end
      users = notify_members.collect(&:user)
    else
      users = []
    end
    # Watchers
    watchers = []
    file&.get_all_watchers(watchers)
    users.concat watchers
    users.delete(User.current) if User.current&.pref&.no_self_notified
    users.uniq
  end
end
