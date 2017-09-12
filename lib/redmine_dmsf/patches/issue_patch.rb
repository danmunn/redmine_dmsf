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
  module Patches
    module IssuePatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          before_destroy :delete_system_folder
        end
      end

      module InstanceMethods

        def save_dmsf_attachments(dmsf_attachments)
          @saved_dmsf_attachments = []
          if dmsf_attachments
            dmsf_attachments = dmsf_attachments.map(&:last)
            dmsf_attachments.each do |dmsf_attachment|
              a = Attachment.find_by_token(dmsf_attachment[:token])
              @saved_dmsf_attachments << a if a
            end
          end
        end

        def saved_dmsf_attachments
          @saved_dmsf_attachments || []
        end

        def save_dmsf_links(dmsf_links)
          @saved_dmsf_links = []
          if dmsf_links
            ids = dmsf_links.map(&:last)
            ids.each do |id|
              l = DmsfLink.find_by_id(id)
              @saved_dmsf_links << l if l
            end
          end
        end

        def saved_dmsf_links
          @saved_dmsf_links || []
        end

        def save_dmsf_attachments_wfs(dmsf_attachments_wfs, dmsf_attachments)
          if dmsf_attachments_wfs
            @dmsf_attachments_wfs = {}
            dmsf_attachments_wfs.each do |attachment_id, approval_workflow_id|
              attachment = dmsf_attachments[attachment_id]
              if attachment
                a = Attachment.find_by_token(attachment[:token])
                wf = DmsfWorkflow.find_by_id approval_workflow_id
                @dmsf_attachments_wfs[a.id] = wf if wf && a
              end
            end
          end
        end

        def saved_dmsf_attachments_wfs
          @dmsf_attachments_wfs || []
        end

        def save_dmsf_links_wfs(dmsf_links_wfs)
          if dmsf_links_wfs
            @saved_dmsf_links_wfs = {}
            dmsf_links_wfs.each do |dmsf_link_id, approval_workflow_id|
              wf = DmsfWorkflow.find_by_id approval_workflow_id
              @saved_dmsf_links_wfs[dmsf_link_id.to_i] = wf if wf
            end
          end
        end

        def saved_dmsf_links_wfs
          @saved_dmsf_links_wfs || {}
        end

        def system_folder(create = false)
          parent = DmsfFolder.system.where(:project_id => self.project_id, :title => '.Issues').first
          if create && !parent
            parent = DmsfFolder.new
            parent.project_id = self.project_id
            parent.title = '.Issues'
            parent.description = 'Documents assigned to issues'
            parent.user_id = User.anonymous.id
            parent.system = true
            parent.save
          end
          if parent
            folder = DmsfFolder.system.where(['project_id = ? AND dmsf_folder_id = ? AND CAST(title AS DECIMAL) = ?',
              self.project_id, parent.id, self.id]).first
            if create && !folder
              folder = DmsfFolder.new
              folder.dmsf_folder_id = parent.id
              folder.project_id = self.project_id
              folder.title = "#{self.id} - #{self.subject}"
              folder.user_id = User.anonymous.id
              folder.system = true
              folder.save
            end
          end
          folder
        end

        def dmsf_files
          files = []
          folder = self.system_folder
          if folder
            files = folder.dmsf_files.to_a
          end
          files
        end

        def dmsf_links
          links = []
          folder = self.system_folder
          if folder
            links = folder.dmsf_links
          end
          links
        end

        def delete_system_folder
          folder = self.system_folder
          folder.destroy if folder
        end

        def dmsf_file_added(dmsf_file)
          unless dmsf_file.new_record?
            self.journalize_dmsf_file(dmsf_file, :added)
          end
        end

        def dmsf_file_removed(dmsf_file)
          unless dmsf_file.new_record?
            self.journalize_dmsf_file(dmsf_file, :removed)
          end
        end

        # Adds a journal detail for an attachment that was added or removed
        def journalize_dmsf_file(dmsf_file, added_or_removed)
          init_journal(User.current)
          key = (added_or_removed == :removed ? :old_value : :value)
          current_journal.details << JournalDetail.new(
            :property => 'dmsf_file',
            :prop_key => dmsf_file.id,
            key => dmsf_file.title
          )
          current_journal.save
        end

      end

    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless Issue.included_modules.include?(RedmineDmsf::Patches::IssuePatch)
    Issue.send(:include, RedmineDmsf::Patches::IssuePatch)
  end
end
