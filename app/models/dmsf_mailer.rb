require "mailer"

class DmsfMailer < Mailer
  
  def files_updated(user, files)
    project = files[0].project
    files = files.select { |file| file.notify? }
    
    redmine_headers "Project" => project.identifier
    recipients get_notify_user_emails(user, files)
    subject project.name + ": Dmsf files updated"
    body :user => user, :files => files, :project => project
    # TODO: correct way should be  render_multipart("files_updated", body), but other plugin broke it
    render_multipart(File.expand_path(File.dirname(__FILE__) + "/../views/dmsf_mailer/" + "files_updated"), body)
  end
  
  def files_deleted(user, files)
    project = files[0].project
    files = files.select { |file| file.notify? }
    
    redmine_headers "Project" => project.identifier
    recipients get_notify_user_emails(user, files)
    subject project.name + ": Dmsf files deleted"
    body :user => user, :files => files, :project => project
    # TODO: correct way should be  render_multipart("files_updated", body), but other plugin broke it
    render_multipart(File.expand_path(File.dirname(__FILE__) + "/../views/dmsf_mailer/" + "files_deleted"), body)
  end
  
  def send_documents(user, email_to, email_cc, email_subject, zipped_content, email_plain_body)
    recipients      email_to
    if !email_cc.strip.blank?
      cc              email_cc
    end
    subject         email_subject
    from            user.mail
    content_type    "multipart/mixed"

    part "text/plain" do |p|
      p.body = email_plain_body
    end
  
    zipped_content_data = open(zipped_content, "rb") {|io| io.read }

    attachment :content_type => "application/zip",
             :filename => "Documents.zip",
             :body => zipped_content_data
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
        dmsf_user_prefs = DmsfUserPref.for(project, notify_user)
        if dmsf_user_prefs.email_notify.nil?
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
        else            dmsf_user_prefs.email_notify
        end
      end
    end      

    notify_members.collect {|m| m.user.mail }
  end
  
end
