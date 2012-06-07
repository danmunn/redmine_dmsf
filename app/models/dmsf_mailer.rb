# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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

require "mailer"

class DmsfMailer < Mailer
  
  def files_updated(user, files)
    project = files[0].project
    files = files.select { |file| file.notify? }
    
    redmine_headers "Project" => project.identifier

    @user = user
    @files = files
    @project = project

    mail :to => get_notify_user_emails(user, files),
      :subject =>  project.name + ": Dmsf files updated"
  end
  
  def files_deleted(user, files)
    project = files[0].project
    files = files.select { |file| file.notify? }
    
    redmine_headers "Project" => project.identifier

    @user = user
    @files = files
    @project = project

    mail :to => get_notify_user_emails(user, files),
      :subject => project.name + ": Dmsf files deleted"
  end
  
  def send_documents(user, email_to, email_cc, email_subject, zipped_content, email_plain_body)
    zipped_content_data = open(zipped_content, "rb") {|io| io.read }

    @body = email_plain_body

    attachments['Documents.zip'] = {:content_type => "application/zip", :content => zipped_content_data}
    mail(:to => email_to, :cc => email_cc, :subject => email_subject, :from => user.mail)
  end
  
  private
  
  def get_notify_user_emails(user, files)
    if files.empty?
      return []
    end
    
    project = files[0].project
    
    notify_members = project.members
    notify_members = notify_members.select do |notify_member|
      notify_user = notify_member.user
      if notify_user.pref[:no_self_notified] && notify_user == user
        false
      else
        if notify_member.dmsf_mail_notification.nil?
          case notify_user.mail_notification
          when 'all'
            true
          when 'selected'
            notify_member.mail_notification?
          when 'only_my_events'
            notify_user.allowed_to?(:file_approval, project) ? true : false
          when 'only_owner'
            notify_user.allowed_to?(:file_approval, project) ? true : false
          else
            false
          end
        else  
          notify_member.dmsf_mail_notification
        end
      end
    end      

    notify_members.collect {|m| m.user.mail }
  end
  
end
