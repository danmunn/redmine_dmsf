# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Hooks
    include Redmine::Hook
    
    class ControllerIssuesHook < RedmineDmsf::Hooks::Listener

      def controller_issues_new_before_save(context={})
        controller_issues_before_save(context)
      end

      def controller_issues_new_after_save(context={})
        controller_issues_after_save(context)
        # Copy documents from the source issue
        if context.is_a?(Hash)
          issue = context[:issue]
          params = context[:params]
          copied_from = Issue.find_by(id: params[:copy_from]) if params[:copy_from].present?
          # Save documents
          if copied_from
            copied_from.dmsf_files.each do |dmsf_file|
              dmsf_file.copy_to(issue.project, issue.system_folder(true))
            end
          end
        end
      end

      def controller_issues_edit_before_save(context={})
        controller_issues_before_save(context)
      end

      def controller_issues_edit_after_save(context={})
        controller_issues_after_save(context, true)
      end

      def controller_issues_bulk_edit_before_save(context={})
        controller_issues_before_save(context)
      end

      # Unfortunately this hook is missing in Redmine. It's called in Easy Redmine only.
      def controller_issues_bulk_edit_after_save(context={})
        controller_issues_after_save(context, true)
      end

      private

      def controller_issues_before_save(context)
        if context.is_a?(Hash)
          issue = context[:issue]
          @new_object = issue.new_record?
          params = context[:params]
          # Save upload preferences DMS/Attachments
          User.current.pref.update_attribute :dmsf_attachments_upload_choice, params[:dmsf_attachments_upload_choice]
          # Save attachments
          issue.save_dmsf_attachments(params[:dmsf_attachments])
          issue.save_dmsf_links(params[:dmsf_links])
          issue.save_dmsf_attachments_wfs(params[:dmsf_attachments_wfs], params[:dmsf_attachments])
          issue.save_dmsf_links_wfs(params[:dmsf_links_wfs])
        end
      end

      def controller_issues_after_save(context, edit = false)
        if context.is_a?(Hash)
          issue = context[:issue]
          params = context[:params]
          controller = context[:controller]
          if edit && ((params[:issue] && params[:issue][:project_id].present?) || context[:new_project])
            project_id = context[:new_project] ? context[:new_project].id : params[:issue][:project_id].to_i
            old_project_id = context[:project] ? context[:project].id : project_id
            # Sync the title with the issue's subject
            old_system_folder = issue.system_folder(false, old_project_id)
            if old_system_folder
              old_system_folder.title = "#{issue.id} - #{DmsfFolder::get_valid_title(issue.subject)}"
              unless old_system_folder.save
                controller.flash[:error] = old_system_folder.errors.full_messages.to_sentence
                Rails.logger.error old_system_folder.errors.full_messages.to_sentence
              end
            end
            # Move documents, links and folders if needed
            if project_id != old_project_id
              if old_system_folder
                new_main_system_folder = issue.main_system_folder(true)
                if new_main_system_folder
                  old_system_folder.dmsf_folder_id = new_main_system_folder.id
                  old_system_folder.project_id = project_id
                  unless old_system_folder.save
                    controller.flash[:error] = old_system_folder.errors.full_messages.to_sentence
                    Rails.logger.error old_system_folder.errors.full_messages.to_sentence
                  end
                  issue.dmsf_files.each do |dmsf_file|
                    dmsf_file.project_id = project_id
                    unless dmsf_file.save
                      controller.flash[:error] = dmsf_file.errors.full_messages.to_sentence
                      Rails.logger.error dmsf_file.errors.full_messages.to_sentence
                    end
                  end
                  issue.dmsf_links.each do | dmsf_link|
                    dmsf_link.project_id = project_id
                    unless dmsf_link.save
                      controller.flash[:error] = dmsf_link.errors.full_messages.to_sentence
                      Rails.logger.error dmsf_link.errors.full_messages.to_sentence
                    end
                  end
                end
              end
            end
          end
          # Attach DMS documents
          uploaded_files = params[:dmsf_attachments]
          if uploaded_files
            system_folder = issue.system_folder(true)
            uploaded_files.each do |key, uploaded_file|
              upload = DmsfUpload.create_from_uploaded_attachment(issue.project, system_folder, uploaded_file)
              if upload
                uploaded_file[:disk_filename] = upload.disk_filename
                uploaded_file[:name] = upload.name
                uploaded_file[:title] = upload.title
                uploaded_file[:version] = 1
                uploaded_file[:size] = upload.size
                uploaded_file[:mime_type] = upload.mime_type
                uploaded_file[:tempfile_path] = upload.tempfile_path
                uploaded_file[:digest] = upload.digest
                if params[:dmsf_attachments_wfs].present? && params[:dmsf_attachments_wfs][key].present?
                  uploaded_file[:workflow_id] = params[:dmsf_attachments_wfs][key].to_i
                end
              end
            end
            DmsfUploadHelper.commit_files_internal uploaded_files, issue.project, system_folder,
             context[:controller], @new_object, issue
          end
          # Attach DMS links
          issue.saved_dmsf_links.each do |l|
            file = l.target_file
            revision = file.last_revision
            system_folder = issue.system_folder(true)
            if system_folder
              l.project_id = system_folder.project_id
              l.dmsf_folder_id = system_folder.id
              if l.save && (!@new_object)
                issue.dmsf_file_added file
              end
              wf = issue.saved_dmsf_links_wfs[l.id]
              if wf
                # Assign the workflow
                revision.set_workflow wf.id, 'assign'
                revision.assign_workflow wf.id
                # Start the workflow
                revision.set_workflow wf.id, 'start'
                if revision.save
                  wf.notify_users issue.project, revision, context[:controller]
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
        end
      end
                  
    end
    
  end
end