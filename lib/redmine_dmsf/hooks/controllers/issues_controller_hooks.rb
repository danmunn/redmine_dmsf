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
    
    class ControllerIssuesHook < RedmineDmsf::Hooks::Listener

      def controller_issues_new_after_save(context={})
        controller_issues_after_save(context)
        # Copy documents from the source issue
        if context.is_a?(Hash)
          issue = context[:issue]
          params = context[:params]
          copied_from = Issue.find_by_id(params[:copy_from]) if params[:copy_from].present?
          # Save documents
          if copied_from
            issue.dmsf_files = copied_from.dmsf_files.map do |dmsf_file|
              dmsf_file.copy_to(issue)
            end
          end
        end
      end

      def controller_issues_edit_after_save(context={})
        controller_issues_after_save(context)
      end

      private

      def controller_issues_after_save(context)
        # Create attached documents
        if context.is_a?(Hash)
          issue = context[:issue]
          params = context[:params]
          uploaded_files = params[:dmsf_attachments]
          if uploaded_files && uploaded_files.is_a?(Hash)
            # standard file input uploads
            uploaded_files.each_value do |uploaded_file|
              upload = DmsfUpload.create_from_uploaded_attachment(issue.project, nil, uploaded_file)
              uploaded_file[:disk_filename] = upload.disk_filename
              uploaded_file[:name] = upload.name
              uploaded_file[:title] = upload.title
            end
            DmsfUploadHelper.commit_files_internal uploaded_files, issue, nil, self
          end
        end
      end
                  
    end
    
  end
end