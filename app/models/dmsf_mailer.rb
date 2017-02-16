# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

class DmsfMailer < Mailer
  layout 'mailer'

  def files_updated(user, project, files)
    if user && project && files.count > 0
      files = files.select { |file| file.notify? }
      redmine_headers 'Project' => project.identifier if project
      @files = files
      @project = project
      message_id project
      set_language_if_valid user.language
      mail :to => user.mail,
        :subject => "[#{@project.name} - #{l(:menu_dmsf)}] #{l(:text_email_doc_updated_subject)}"
    end
  end

  def files_deleted(user, project, files)
    if user && files.count > 0
      files = files.select { |file| file.notify? }
      redmine_headers 'Project' => project.identifier if project
      @files = files
      @project = project
      message_id project
      set_language_if_valid user.language
      mail :to => user.mail,
        :subject => "[#{@project.name} - #{l(:menu_dmsf)}] #{l(:text_email_doc_deleted_subject)}"
    end
  end

  def send_documents(project, user, email_params)
    zipped_content_data = open(email_params[:zipped_content], 'rb') { |io| io.read }
    redmine_headers 'Project' => project.identifier if project
    @body = email_params[:body]
    @links_only = email_params[:links_only] == '1'
    @public_urls = email_params[:public_urls] == '1'
    @expired_at = email_params[:expired_at]
    @folders = email_params[:folders]
    @files = email_params[:files]

    unless @links_only
      attachments['Documents.zip'] = { :content_type => 'application/zip', :content => zipped_content_data }
    end
    mail :to => email_params[:to], :cc => email_params[:cc],
      :subject => email_params[:subject], 'From' => email_params[:from]
  end

  def workflow_notification(user, workflow, revision, subject_id, text1_id, text2_id, notice = nil)
    if user && workflow && revision
      if revision.dmsf_file && revision.dmsf_file.project
        @project = revision.dmsf_file.project
        redmine_headers 'Project' => @project.identifier
      end
      set_language_if_valid user.language
      @user = user
      message_id workflow
      @workflow = workflow
      @revision = revision
      @text1 = l(text1_id, :name => workflow.name, :filename => revision.dmsf_file.name, :notice => notice)
      @text2 = l(text2_id)
      @notice = notice
      mail :to => user.mail,
        :subject => "[#{@project.name} - #{l(:field_label_dmsf_workflow)}] #{@workflow.name} #{l(subject_id)}"
    end
  end

  def self.get_notify_users(project, files = [])
    if files.present?
      notify_files = files.select { |file| file.notify? }
      return [] if notify_files.empty?
    end
    notify_members = project.members.select do |notify_member|
      notify_user = notify_member.user
      if notify_user == User.current && notify_user.pref.no_self_notified
        false
      else
        if notify_member.dmsf_mail_notification.nil?
          case notify_user.mail_notification
          when 'all'
            true
          when 'selected'
            notify_member.mail_notification?
            when 'only_my_events'
              author = false
              files.each do |file|
                if file.involved?(notify_user)
                  author = true
                  break
                end
              end
              author
          when 'only_owner', 'only_assigned'
            author = false
            files.each do |file|
              if file.owner?(notify_user)
                author = true
                break
              end
            end
            author
          else
            false
          end
        else
          notify_member.dmsf_mail_notification
        end
      end
    end

    notify_members.collect { |m| m.user }.uniq
  end

end