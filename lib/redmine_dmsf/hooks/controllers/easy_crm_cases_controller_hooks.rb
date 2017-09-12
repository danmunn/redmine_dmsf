# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
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

module RedmineDmsf
  module Hooks
    include Redmine::Hook
    
    class ControllerEasyCrmCasesHook < RedmineDmsf::Hooks::Listener

      def controller_easy_crm_cases_before_save(context={})
        if context.is_a?(Hash)
          easy_crm_case = context[:easy_crm_case]
          params = context[:params]
          easy_crm_case.save_dmsf_attachments(params[:dmsf_attachments])
          easy_crm_case.save_dmsf_links(params[:dmsf_links])
          easy_crm_case.save_dmsf_attachments_wfs(params[:dmsf_attachments_wfs], params[:dmsf_attachments])
          easy_crm_case.save_dmsf_links_wfs(params[:dmsf_links_wfs])
        end
      end

      def controller_easy_crm_cases_after_save(context={})
        easy_crm_cases_after_save(context)
        # Copy documents from the source issue
        if context.is_a?(Hash)
          easy_crm_case = context[:easy_crm_case]
          params = context[:params]
          copied_from = EasyCrmCase.find_by_id(params[:copy_from]) if params[:copy_from].present?
          # Save documents
          if copied_from
            copied_from.dmsf_files.each do |dmsf_file|
              dmsf_file.copy_to(easy_crm_case.project, easy_crm_cases.system_folder(true))
            end
          end
        end
      end

      private

      def easy_crm_cases_after_save(context)
        if context.is_a?(Hash)
          easy_crm_case = context[:easy_crm_case]
          params = context[:params]
          # Attach DMS documents
          uploaded_files = params[:dmsf_attachments]
          if uploaded_files && uploaded_files.is_a?(Hash)
            system_folder = easy_crm_case.system_folder(true)
            uploaded_files.each do |key, uploaded_file|
              upload = DmsfUpload.create_from_uploaded_attachment(easy_crm_case.project, system_folder, uploaded_file)
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
            DmsfUploadHelper.commit_files_internal uploaded_files, easy_crm_case.project, system_folder,
             context[:controller]
          end
          # Attach DMS links
          easy_crm_case.saved_dmsf_links.each do |l|
            file = l.target_file
            revision = file.last_revision
            system_folder = easy_crm_case.system_folder(true)
            if system_folder
              l.project_id = system_folder.project_id
              l.dmsf_folder_id = system_folder.id
              if l.save
                easy_crm_case.dmsf_file_added file
              end
              wf = easy_crm_case.saved_dmsf_links_wfs[l.id]
              if wf
                # Assign the workflow
                revision.set_workflow(wf.id, 'assign')
                revision.assign_workflow(wf.id)
                # Start the workflow
                revision.set_workflow(wf.id, 'start')
                if revision.save
                  wf.notify_users(easy_crm_case.project, revision, context[:controller])
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