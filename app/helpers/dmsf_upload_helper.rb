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

module DmsfUploadHelper
  include Redmine::I18n

  def self.commit_files_internal(commited_files, project, folder, controller)
    failed_uploads = []
    files = []
    if commited_files && commited_files.is_a?(Hash)
      failed_uploads = []
      commited_files.each_value do |commited_file|
        name = commited_file[:name]
        new_revision = DmsfFileRevision.new
        file = DmsfFile.visible.find_file_by_name(project, folder, name)
        unless file
          link = DmsfLink.find_link_by_file_name(project, folder, name)
          file = link.target_file if link
        end

        unless file
          file = DmsfFile.new
          file.project_id = project.id
          file.name = name
          file.dmsf_folder = folder
          file.notification = Setting.plugin_redmine_dmsf['dmsf_default_notifications'].present?
          new_revision.minor_version = 0
          new_revision.major_version = 0
        else
          if file.last_revision
            last_revision = file.last_revision
            new_revision.source_revision = last_revision
            new_revision.major_version = last_revision.major_version
            new_revision.minor_version = last_revision.minor_version
          else
            new_revision.minor_version = 0
            new_revision.major_version = 0
          end
        end

        if file.locked_for_user?
          failed_uploads.push(commited_file)
          next
        end

        new_revision.dmsf_file = file
        new_revision.user = User.current
        new_revision.name = name
        new_revision.title = commited_file[:title]
        new_revision.description = commited_file[:description]
        new_revision.comment = commited_file[:comment]
        version = commited_file[:version].to_i
        if version == 3
          new_revision.major_version = commited_file[:custom_version_major].to_i
          new_revision.minor_version = commited_file[:custom_version_minor].to_i
        else
          new_revision.increase_version(version)
        end
        new_revision.mime_type = commited_file[:mime_type]
        new_revision.size = commited_file[:size]
        new_revision.digest = DmsfFileRevision.create_digest commited_file[:tempfile_path]

        if commited_file[:custom_field_values].present?
          commited_file[:custom_field_values].each_with_index do |v, i|
            new_revision.custom_field_values[i].value = v[1]
          end
        end

        # Need to save file first to generate id for it in case of creation.
        # File id is needed to properly generate revision disk filename
        if new_revision.valid? && file.save
          new_revision.disk_filename = new_revision.new_storage_filename
        else
          Rails.logger.error (new_revision.errors.full_messages + file.errors.full_messages).to_sentence
          failed_uploads.push(commited_file)
          next
        end

        if new_revision.save
          new_revision.assign_workflow(commited_file[:dmsf_workflow_id])
          begin
            FileUtils.mv commited_file[:tempfile_path], new_revision.disk_file(false)
            FileUtils.chmod 'u=wr,g=r', new_revision.disk_file(false)
            file.set_last_revision new_revision
            files.push(file)
            if file.container.is_a?(Issue)
              file.container.dmsf_file_added(file)
            end
          rescue Exception => e
            Rails.logger.error e.message
            controller.flash[:error] = e.message
            failed_uploads.push(file)
          end
        else
          failed_uploads.push(commited_file)
        end
        # Approval workflow
        if commited_file[:workflow_id].present?
          wf = DmsfWorkflow.find_by_id commited_file[:workflow_id]
          if wf
            # Assign the workflow
            new_revision.set_workflow(wf.id, 'assign')
            new_revision.assign_workflow(wf.id)
            # Start the workflow
            new_revision.set_workflow(wf.id, 'start')
            if new_revision.save
              wf.notify_users(project, new_revision, controller)
              begin
                file.lock!
              rescue DmsfLockError => e
                Rails.logger.warn e.message
              end
            else
              Rails.logger.error l(:error_workflow_assign)
            end
          end
        end
      end
      # Notifications
      if ((folder && folder.notification?) || (!folder && project.dmsf_notification?))
        begin
          recipients = DmsfMailer.get_notify_users(project, files)
          recipients.each do |u|
            DmsfMailer.files_updated(u, project, files).deliver
          end
          if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'] == '1'
            unless recipients.empty?
              to = recipients.collect{ |r| r.name }.first(DMSF_MAX_NOTIFICATION_RECEIVERS_INFO).join(', ')
              to << ((recipients.count > DMSF_MAX_NOTIFICATION_RECEIVERS_INFO) ? ',...' : '.')
              controller.flash[:warning] = l(:warning_email_notifications, :to => to)
            end
          end
        rescue Exception => e
          Rails.logger.error "Could not send email notifications: #{e.message}"
        end
      end
    end
    if failed_uploads.present?
      controller.flash[:warning] = l(:warning_some_files_were_not_commited, :files => failed_uploads.map{|u| u['name']}.join(', '))
    end
    [files, failed_uploads]
  end

end
