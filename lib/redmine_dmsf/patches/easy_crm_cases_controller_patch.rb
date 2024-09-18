# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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
#
module RedmineDmsf
  module Patches
    # Easy CRM cases controller
    module EasyCrmCasesControllerPatch
      ##################################################################################################################
      # Overridden methods

      def easy_crm_after_save
        super
        easy_crm_cases = @easy_crm_cases
        easy_crm_cases ||= [@easy_crm_case]
        easy_crm_cases.each do |easy_crm_case|
          # Attach DMS documents
          uploaded_files = params[:dmsf_attachments]
          if uploaded_files
            system_folder = easy_crm_case.system_folder(create: true)
            uploaded_files.each do |key, uploaded_file|
              upload = DmsfUpload.create_from_uploaded_attachment(easy_crm_case.project, system_folder, uploaded_file)
              next unless upload

              uploaded_file[:disk_filename] = upload.disk_filename
              uploaded_file[:name] = upload.name
              uploaded_file[:title] = upload.title
              uploaded_file[:description] = details[key][:description]
              uploaded_file[:comment] = details[key][:comment]
              uploaded_file[:version_major] = details[key][:version_major]
              uploaded_file[:version_minor] = details[key][:version_minor]
              uploaded_file[:version_patch] = details[key][:version_patch]
              uploaded_file[:size] = upload.size
              uploaded_file[:mime_type] = upload.mime_type
              uploaded_file[:tempfile_path] = upload.tempfile_path
              uploaded_file[:digest] = upload.digest
              if params[:dmsf_attachments_wfs].present? && params[:dmsf_attachments_wfs][key].present?
                uploaded_file[:workflow_id] = params[:dmsf_attachments_wfs][key].to_i
              end
              uploaded_file[:custom_field_values] = details[key][:custom_field_values]
            end
            DmsfUploadHelper.commit_files_internal uploaded_files, easy_crm_case.project, system_folder, self,
                                                   easy_crm_case, new_object: false
          end
          # Attach DMS links
          easy_crm_case.saved_dmsf_links.each do |l|
            file = l.target_file
            revision = file.last_revision
            system_folder = easy_crm_case.system_folder(create: true)
            next unless system_folder

            l.project_id = system_folder.project_id
            l.dmsf_folder_id = system_folder.id
            easy_crm_case.dmsf_file_added(file) if l.save
            wf = easy_crm_case.saved_dmsf_links_wfs[l.id]
            next unless wf

            # Assign the workflow
            revision.set_workflow wf.id, 'assign'
            revision.assign_workflow wf.id
            # Start the workflow
            revision.set_workflow wf.id, 'start'
            if revision.save
              wf.notify_users easy_crm_case.project, revision, self
              begin
                file.lock!
              rescue RedmineDmsf::Errors::DmsfLockError => e
                Rails.logger.warn e.message
              end
            else
              Rails.logger.error l(:error_workflow_assign)
            end
          end
          copied_from = EasyCrmCase.find_by(id: params[:copy_from]) if params[:copy_from].present?
          # Save documents
          next unless copied_from

          copied_from.dmsf_files.each do |dmsf_file|
            dmsf_file.copy_to easy_crm_case.project, easy_crm_cases.system_folder(create: true)
          end
        end
      end

      ##################################################################################################################
      # New methods

      def self.prepended(base)
        base.class_eval do
          before_action :controller_easy_crm_cases_before_save, only: %i[create update bulk_update]
        end
      end

      def controller_easy_crm_cases_before_save
        easy_crm_cases = @easy_crm_cases
        easy_crm_cases ||= [@easy_crm_case]
        easy_crm_cases.each do |easy_crm_case|
          easy_crm_case.save_dmsf_attachments(params[:dmsf_attachments])
          easy_crm_case.save_dmsf_links(params[:dmsf_links])
          easy_crm_case.save_dmsf_attachments_wfs(params[:dmsf_attachments_wfs], params[:dmsf_attachments])
          easy_crm_case.save_dmsf_links_wfs(params[:dmsf_links_wfs])
        end
      end
    end
  end
end

# Apply the patch
if Redmine::Plugin.installed?('easy_crm')
  EasyPatchManager.register_controller_patch 'EasyCrmCasesController',
                                             'RedmineDmsf::Patches::EasyCrmCasesControllerPatch',
                                             prepend: true
end
