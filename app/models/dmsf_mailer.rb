# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
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
      
      set_language_if_valid user.language
      mail :to => user.mail, 
          :subject =>  l(:text_email_doc_updated_subject, :project => project.name)
    end
  end
  
  def files_deleted(user, project, files)
    if user && files.count > 0      
      files = files.select { |file| file.notify? }

      redmine_headers 'Project' => project.identifier if project
      
      @files = files
      @project = project
      
      set_language_if_valid user.language
      mail :to => user.mail, 
        :subject =>  l(:text_email_doc_deleted_subject, :project => project.name)
    end
  end
    
  def send_documents(project, user, email_params)    
    zipped_content_data = open(email_params[:zipped_content], 'rb') { |io| io.read }
    
    redmine_headers 'Project' => project.identifier if project

    @body = email_params[:body]
    @links_only = email_params[:links_only]
    @folders = email_params[:folders]
    @files = email_params[:files]
    
    unless @links_only == '1'
      attachments['Documents.zip'] = { :content_type => 'application/zip', :content => zipped_content_data }
    end
    
    mail :to => email_params[:to], :cc => email_params[:cc], :subject => email_params[:subject], :from => user.mail
  end
  
  def workflow_notification(user, workflow, revision, subject_id, text1_id, text2_id, notice = nil)
    if user && workflow && revision
      if revision.file && revision.file.project
        @project = revision.file.project
        redmine_headers 'Project' => @project.identifier
      end
      set_language_if_valid user.language
      @user = user
      @workflow = workflow
      @revision = revision      
      @text1 = l(text1_id, :name => workflow.name, :filename => revision.file.name, :notice => notice)      
      @text2 = l(text2_id)
      @notice = notice
      mail :to => user.mail, :subject => l(subject_id, :name => workflow.name)
    end
  end        
  
  def self.get_notify_users(project, files = nil)
    if files
      notify_files = files.select { |file| file.notify? }
      return [] if notify_files.empty?
    end        
    notify_members = project.members
    notify_members = notify_members.select do |notify_member|
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
          when 'only_my_events', 'only_owner'
            notify_user.allowed_to?(:file_manipulation, project)
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