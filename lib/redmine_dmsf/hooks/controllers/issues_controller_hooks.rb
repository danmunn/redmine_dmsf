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

module RedmineDmsf
  module Hooks
    module Controllers
      # issue controller hooks
      class IssuesControllerHooks < Redmine::Hook::Listener
        def controller_issues_new_before_save(context = {})
          controller_issues_before_save context
        end

        def controller_issues_new_after_save(context = {})
          controller_issues_after_save context
          # Copy documents from the source issue
          return unless context.is_a?(Hash)

          issue = context[:issue]
          params = context[:params]
          copied_from = Issue.find_by(id: params[:copy_from]) if params[:copy_from].present?
          # Save documents
          return unless copied_from

          copied_from.dmsf_files.each do |dmsf_file|
            dmsf_file.copy_to issue.project, issue.system_folder(create: true)
          end
        end

        def controller_issues_edit_before_save(context = {})
          controller_issues_before_save context
        end

        def controller_issues_edit_after_save(context = {})
          controller_issues_after_save context, edit: true
        end

        def controller_issues_bulk_edit_before_save(context = {})
          controller_issues_before_save context
          # Call also the after safe hook, 'cause it's missing in Redmine
          controller_issues_after_save(context, edit: true) unless defined?(EasyExtensions)
        end

        # Unfortunately this hook is missing in Redmine. It's called in Easy Redmine only.
        def controller_issues_bulk_edit_after_save(context = {})
          controller_issues_after_save context, edit: true
        end

        private

        def controller_issues_before_save(context)
          return unless context.is_a?(Hash)

          issue = context[:issue]
          @new_object = issue.new_record?
          params = context[:params]
          # Save upload preferences DMS/Attachments
          User.current.pref.dmsf_attachments_upload_choice = params[:dmsf_attachments_upload_choice]
          # Save attachments
          issue.save_dmsf_attachments params[:dmsf_attachments]
          issue.save_dmsf_links params[:dmsf_links]
          issue.save_dmsf_attachments_wfs params[:dmsf_attachments_wfs], params[:dmsf_attachments]
          issue.save_dmsf_links_wfs params[:dmsf_links_wfs]
        end

        def controller_issues_after_save(context, edit: false)
          return unless context.is_a?(Hash)

          issue = context[:issue]
          params = context[:params]
          controller = context[:controller]
          if edit && ((params[:issue] && params[:issue][:project_id].present?) || context[:new_project])
            project_id = context[:new_project] ? context[:new_project].id : params[:issue][:project_id].to_i
            old_project_id = context[:project] ? context[:project].id : project_id
            # Sync the title with the issue's subject
            old_system_folder = issue.system_folder(create: false, prj_id: old_project_id)
            if old_system_folder
              old_system_folder.title = "#{issue.id} - #{DmsfFolder.get_valid_title(issue.subject)}"
              unless old_system_folder.save
                controller.flash[:error] = old_system_folder.errors.full_messages.to_sentence
                Rails.logger.error old_system_folder.errors.full_messages.to_sentence
              end
            end
            # Move documents, links and folders if needed
            if project_id != old_project_id
              if old_system_folder
                new_main_system_folder = issue.main_system_folder(create: true)
                if new_main_system_folder
                  old_system_folder.dmsf_folder_id = new_main_system_folder.id
                  old_system_folder.project_id = project_id
                  unless old_system_folder.save
                    controller.flash[:error] = old_system_folder.errors.full_messages.to_sentence
                    Rails.logger.error old_system_folder.errors.full_messages.to_sentence
                  end
                  issue.dmsf_files.each do |dmsf_file|
                    dmsf_file.project_id = project_id
                    next if dmsf_file.save

                    controller.flash[:error] = dmsf_file.errors.full_messages.to_sentence
                    Rails.logger.error dmsf_file.errors.full_messages.to_sentence
                  end
                  issue.dmsf_links.each do |dmsf_link|
                    dmsf_link.project_id = project_id
                    next if dmsf_link.save

                    controller.flash[:error] = dmsf_link.errors.full_messages.to_sentence
                    Rails.logger.error dmsf_link.errors.full_messages.to_sentence
                  end
                end
              end

              issue.descendants.each do |i|
                old_system_folder = i.system_folder(create: false, prj_id: old_project_id)
                next unless old_system_folder

                new_main_system_folder = i.main_system_folder(create: true)
                if new_main_system_folder
                  old_system_folder.dmsf_folder_id = new_main_system_folder.id
                  old_system_folder.project_id = project_id
                  unless old_system_folder.save
                    controller.flash[:error] = old_system_folder.errors.full_messages.to_sentence
                    Rails.logger.error old_system_folder.errors.full_messages.to_sentence
                  end
                  i.dmsf_files.each do |dmsf_file|
                    dmsf_file.project_id = project_id
                    next if dmsf_file.save

                    controller.flash[:error] = dmsf_file.errors.full_messages.to_sentence
                    Rails.logger.error dmsf_file.errors.full_messages.to_sentence
                  end
                end
                i.dmsf_links.each do |dmsf_link|
                  dmsf_link.project_id = project_id
                  next if dmsf_link.save

                  controller.flash[:error] = dmsf_link.errors.full_messages.to_sentence
                  Rails.logger.error dmsf_link.errors.full_messages.to_sentence
                end
              end
            end
          end
          # Attach DMS documents
          uploaded_files = params[:dmsf_attachments]
          details = params[:committed_files]
          if uploaded_files && details
            system_folder = issue.system_folder(create: true)
            uploaded_files.each do |key, uploaded_file|
              upload = DmsfUpload.create_from_uploaded_attachment(issue.project, system_folder, uploaded_file)
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
            DmsfUploadHelper.commit_files_internal uploaded_files, issue.project, system_folder, context[:controller],
                                                   issue, new_object: @new_object
          end
          # Attach DMS links
          issue.saved_dmsf_links.each do |l|
            file = l.target_file
            revision = file.last_revision
            system_folder = issue.system_folder(create: true)
            next unless system_folder

            l.project_id = system_folder.project_id
            l.dmsf_folder_id = system_folder.id
            issue.dmsf_file_added(file) if l.save && !@new_object
            wf = issue.saved_dmsf_links_wfs[l.id]
            next unless wf

            # Assign the workflow
            revision.set_workflow wf.id, 'assign'
            revision.assign_workflow wf.id
            # Start the workflow
            revision.set_workflow wf.id, 'start'
            if revision.save
              wf.notify_users issue.project, revision, context[:controller]
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
    end
  end
end
