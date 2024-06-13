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
  module Patches
    # Easy CRM case
    module EasyCrmCasePatch
      ##################################################################################################################
      # New methods

      def self.included(base)
        base.class_eval do
          before_destroy :delete_system_folder, prepend: true
        end
      end

      def attributes_editable?
        true
      end

      def save_dmsf_attachments(dmsf_attachments)
        @saved_dmsf_attachments = []
        return unless dmsf_attachments

        dmsf_attachments.each do |_, dmsf_attachment|
          a = Attachment.find_by_token(dmsf_attachment[:token])
          @saved_dmsf_attachments << a if a
        end
      end

      def saved_dmsf_attachments
        @saved_dmsf_attachments || []
      end

      def save_dmsf_links(dmsf_links)
        @saved_dmsf_links = []
        return unless dmsf_links

        dmsf_links.each do |_, id|
          l = DmsfLink.find_by(id: id)
          @saved_dmsf_links << l if l
        end
      end

      def saved_dmsf_links
        @saved_dmsf_links || []
      end

      def save_dmsf_attachments_wfs(dmsf_attachments_wfs, dmsf_attachments)
        return unless dmsf_attachments_wfs

        @dmsf_attachments_wfs = {}
        dmsf_attachments_wfs.each do |attachment_id, approval_workflow_id|
          attachment = dmsf_attachments[attachment_id]
          next unless attachment

          a = Attachment.find_by_token(attachment[:token])
          wf = DmsfWorkflow.find_by(id: approval_workflow_id)
          @dmsf_attachments_wfs[a.id] = wf if wf && a
        end
      end

      def saved_dmsf_attachments_wfs
        @dmsf_attachments_wfs || []
      end

      def save_dmsf_links_wfs(dmsf_links_wfs)
        return unless dmsf_links_wfs

        @saved_dmsf_links_wfs = {}
        dmsf_links_wfs.each do |dmsf_link_id, approval_workflow_id|
          wf = DmsfWorkflow.find_by(id: approval_workflow_id)
          @saved_dmsf_links_wfs[dmsf_link_id.to_i] = wf if wf
        end
      end

      def saved_dmsf_links_wfs
        @saved_dmsf_links_wfs || {}
      end

      def system_folder(create: false)
        parent = DmsfFolder.issystem.find_by(project_id: project_id, title: '.CRM cases')
        if create && !parent
          parent = DmsfFolder.new
          parent.project_id = project_id
          parent.title = '.CRM cases'
          parent.description = 'Documents assigned to CRM cases'
          parent.user_id = User.anonymous.id
          parent.system = true
          parent.save
        end
        if parent
          folder = DmsfFolder.issystem.where(["project_id = ? AND dmsf_folder_id = ? AND title LIKE '? - %'",
                                              project_id, parent.id, id]).first
          if create && !folder
            folder = DmsfFolder.new
            folder.dmsf_folder_id = parent.id
            folder.project_id = project_id
            folder.title = "#{id} - #{name}"
            folder.user_id = User.anonymous.id
            folder.system = true
            folder.save
          end
        end
        folder
      end

      def dmsf_files
        system_folder&.dmsf_files || []
      end

      def dmsf_links
        system_folder&.dmsf_links || []
      end

      def delete_system_folder
        system_folder&.destroy
      end

      def dmsf_file_added(dmsf_file)
        journalize_dmsf_file dmsf_file, :added
      end

      def dmsf_file_removed(dmsf_file)
        journalize_dmsf_file dmsf_file, :removed
      end

      # Adds a journal detail for an attachment that was added or removed
      def journalize_dmsf_file(dmsf_file, added_or_removed)
        key = added_or_removed == :removed ? :old_value : :value
        init_journal User.current
        current_journal.details << JournalDetail.new(
          property: 'dmsf_file',
          prop_key: dmsf_file.id,
          key => dmsf_file.title
        )
        current_journal.save
      end
    end
  end
end

# Apply the patch
if Redmine::Plugin.installed?('easy_crm')
  EasyPatchManager.register_model_patch 'EasyCrmCase', 'RedmineDmsf::Patches::EasyCrmCasePatch'
end
