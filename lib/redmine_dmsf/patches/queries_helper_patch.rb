# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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
    module QueriesHelperPatch

      ##################################################################################################################
      # Overridden methods

      def column_value(column, item, value)
        unless item.is_a? DmsfFolder
          return super column, item, value
        end
        case column.name
        when :id
          case item.type
          when 'DmsfFile', 'DmsfFileLink'
            link_to h(value), dmsf_file_path(id: item.id)
          when 'DmsfFolder', 'DmsfFolderLink'
            if(item.id)
              link_to h(value), edit_dmsf_path(id: item.project_id, folder_id: item.id)
            else
              link_to h(item.project_id), edit_root_dmsf_path(id: item.project_id)
             end
          else
            h(value)
          end
        when :author
          link_to "#{item.firstname} #{item.lastname}", user_path(id: value)
        when :title
          case item.type
          when 'DmsfFolder', 'DmsfFolderLink'
            link_to(h(value),
              dmsf_folder_path(id: item.project_id, folder_id: item.id),
              class: 'icon icon-folder',
              title: h(value)) +
              content_tag('div', item.filename, class: 'dmsf_filename', title: l(:title_filename_for_download))
          when 'DmsfFile', 'DmsfFileLink'
            file_view_url = url_for({ controller: :dmsf_files, action: 'view', id: item.id })
            content_type = Redmine::MimeType.of(value)
            content_type = 'application/octet-stream' if content_type.blank?
            link_to(h(value),
                 file_view_url,
                 target: '_blank',
                 class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}",
                 title: h(value),
                 'data-downloadurl': "#{content_type}:#{h(value)}:#{file_view_url}") +
                content_tag('div', item.filename, class: 'dmsf_filename', title: l(:title_filename_for_download))
          when 'DmsfUrlLink'
            link_to(h(value), item.filename, target: '_blank', class: 'icon icon-link') +
                content_tag('div', item.filename, class: 'dmsf_filename', title: l(:title_filename_for_download))
          else
            h(value)
          end
        when :size
          number_to_human_size(value)
        when :workflow
          if value
            link_to h(DmsfWorkflowStepAction.workflow_str(value)),
                log_dmsf_workflow_path(project_id: item.project_id, id: item.workflow_id,
                                       dmsf_file_revision_id: item.revision_id),
                remote: true
          end
        else
          super column, item, value
        end
      end

    end
  end
end

RedmineExtensions::PatchManager.register_helper_patch 'QueriesHelper',
  'RedmineDmsf::Patches::QueriesHelperPatch', prepend: true