# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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
          copied_from = Issue.find_by_id(params[:copy_from]) if params[:copy_from].present?
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

      private

      def controller_issues_before_save(context)
        if context.is_a?(Hash)
          issue = context[:issue]
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
          # Move existing attached documents if needed
          if edit && params[:issue]
            project_id = params[:issue][:project_id].to_i
            old_project_id = context[:project].id
            system_folder = issue.system_folder(false, old_project_id)
            if system_folder
              # Change the title if the issue's subject changed
              system_folder.title = "#{issue.id} - #{DmsfFolder::get_valid_title(issue.subject)}"
              # Move system folders if needed
              if  system_folder.dmsf_folder
                system_folder.dmsf_folder.project_id = project_id
                system_folder.dmsf_folder.save!
              end
              system_folder.project_id = project_id
              system_folder.save!
              # Move documents
              issue.dmsf_files.each do |dmsf_file|
                dmsf_file.project_id = project_id
                dmsf_file.save!
              end
              # Move links
              issue.dmsf_links.each do | dmsf_link|
                dmsf_link.project_id = project_id
                dmsf_link.save!
              end
            end
          end
          # Attach DMS documents
          uploaded_files = params[:dmsf_attachments]
          if uploaded_files && uploaded_files.is_a?(Hash)
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
                if params[:dmsf_attachments_wfs].present? && params[:dmsf_attachments_wfs][key].present?
                  uploaded_file[:workflow_id] = params[:dmsf_attachments_wfs][key].to_i
                end
              end
            end
            DmsfUploadHelper.commit_files_internal uploaded_files, issue.project, system_folder,
             context[:controller]
          end
          # Attach DMS links
          issue.saved_dmsf_links.each do |l|
            file = l.target_file
            revision = file.last_revision
            system_folder = issue.system_folder(true)
            if system_folder
              l.project_id = system_folder.project_id
              l.dmsf_folder_id = system_folder.id
              if l.save
                issue.dmsf_file_added file
              end
              wf = issue.saved_dmsf_links_wfs[l.id]
              if wf
                # Assign the workflow
                revision.set_workflow(wf.id, 'assign')
                revision.assign_workflow(wf.id)
                # Start the workflow
                revision.set_workflow(wf.id, 'start')
                if revision.save
                  wf.notify_users(issue.project, revision, context[:controller])
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