# encoding: utf-8
# frozen_string_literal: true
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-22 Karel Pičman <karel.picman@lbcfree.net>
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

  def self.commit_files_internal(commited_files, project, folder, controller = nil, new_object = false, container = nil)
    failed_uploads = []
    files = []
    if commited_files
      failed_uploads = []
      commited_files.each do |_, commited_file|
        name = commited_file[:name]
        new_revision = DmsfFileRevision.new
        file = DmsfFile.visible.find_file_by_name(project, folder, name)
        unless file
          link = DmsfLink.find_link_by_file_name(project, folder, name)
          file = link.target_file if link
        end
        if file
          if file.last_revision
            last_revision = file.last_revision
            new_revision.source_revision = last_revision
          end
        else
          file = DmsfFile.new
          file.project_id = project.id
          file.name = name
          file.dmsf_folder = folder
          file.notification = Setting.plugin_redmine_dmsf['dmsf_default_notifications'].present?
        end
        if file.locked_for_user?
          failed_uploads.push file
          next
        end
        new_revision.dmsf_file = file
        new_revision.user = User.current
        new_revision.name = name
        new_revision.title = commited_file[:title]
        new_revision.description = commited_file[:description]
        new_revision.comment = commited_file[:comment]
        new_revision.major_version = commited_file[:version_major].present? ? DmsfUploadHelper::db_version(commited_file[:version_major]) : 1
        new_revision.minor_version = commited_file[:version_minor].present? ? DmsfUploadHelper::db_version(commited_file[:version_minor]) : 0
        new_revision.patch_version = commited_file[:version_patch].present? ? DmsfUploadHelper::db_version(commited_file[:version_patch]) : nil
        new_revision.mime_type = commited_file[:mime_type]
        new_revision.size = commited_file[:size]
        new_revision.digest = commited_file[:digest]

        if commited_file[:custom_field_values].present?
          i = 0
          commited_file[:custom_field_values].each do |_, v|
            new_revision.custom_field_values[i].value = v
            i = i + 1
          end
        end

        # Need to save file first to generate id for it in case of creation.
        # File id is needed to properly generate revision disk filename
        unless new_revision.valid?
          Rails.logger.error new_revision.errors.full_messages.to_sentence
          failed_uploads.push new_revision
          next
        end
        unless file.save
          Rails.logger.error file.errors.full_messages.to_sentence
          failed_uploads.push file
          next
        end

        new_revision.disk_filename = new_revision.new_storage_filename

        if new_revision.save
          new_revision.assign_workflow commited_file[:dmsf_workflow_id]
          begin
            FileUtils.mv commited_file[:tempfile_path], new_revision.disk_file(false)
            FileUtils.chmod 'u=wr,g=r', new_revision.disk_file(false)
            file.set_last_revision new_revision
            files.push file
            if container && (!new_object)
              container.dmsf_file_added file
            end
            Redmine::Hook.call_hook :dmsf_helper_upload_after_commit, { file: file }
          rescue => e
            Rails.logger.error e.message
            controller.flash[:error] = e.message if controller
            failed_uploads.push file
          end
        else
          failed_uploads.push new_revision
        end
        # Approval workflow
        if commited_file[:workflow_id].present?
          wf = DmsfWorkflow.find_by(id: commited_file[:workflow_id])
          if wf
            # Assign the workflow
            new_revision.set_workflow wf.id, 'assign'
            new_revision.assign_workflow wf.id
            # Start the workflow
            new_revision.set_workflow wf.id, 'start'
            if new_revision.save
              wf.notify_users project, new_revision, controller
              begin
                file.lock!
              rescue RedmineDmsf::Errors::DmsfLockError => e
                Rails.logger.warn e.message
              end
            else
              Rails.logger.error l(:error_workflow_assign)
            end
          end
        end
      end
      # Notifications
      begin
        recipients = DmsfMailer.deliver_files_updated(project, files)
        if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
          unless recipients.empty?
            to = recipients.collect{ |r| r.name }.first(Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i).join(', ')
            to << ((recipients.count > Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i) ? ',...' : '.')
            controller.flash[:warning] = l(:warning_email_notifications, to: to) if controller
          end
        end
      rescue => e
        Rails.logger.error "Could not send email notifications: #{e.message}"
      end
    end
    if failed_uploads.present? && controller
      controller.flash[:warning] = l(:warning_some_files_were_not_commited,
                                     files: failed_uploads.map{ |u| u['name'] }.join(', '))
    end
    [files, failed_uploads]
  end

  # 0..99, A..Z except O
  def self.major_version_select_options
    (0..99).to_a + ('A'..'Y').to_a - ['O']
  end

  # 0..999, ' '
  def self.minor_version_select_options
    (0..999).to_a + [' ']
  end

  class <<self
    alias_method :patch_version_select_options, :minor_version_select_options
  end

  # 1 -> 2, -1 -> -2, A -> B
  def self.increase_version(version)
    version ||= 0
    return 1 if ((version == ' ') || ((-version) == ' '.ord))
    if Integer(version)
      if version >= 0
        if (version + 1) < 1000
          version + 1
        else
          version
        end
      else
        if -(version - 1) < 'Z'.ord
          version - 1
        else
          version
        end
      end
    end
    rescue
      if (version.ord + 1) < 'Z'.ord
        (version.ord + 1).chr
      else
        version
      end
  end

  # 1 -> 1, -65 -> A
  def self.gui_version(version)
    return ' ' unless version
    return version if version >= 0
    (-version).chr
  end

  # 1 -> 1, A -> -65
  def self.db_version(version)
    return nil if(version.nil? || version == '&nbsp;')
    version.to_i if Integer(version)
  rescue
    version = ' ' if version.blank?
    -(version.ord)
  end

end
