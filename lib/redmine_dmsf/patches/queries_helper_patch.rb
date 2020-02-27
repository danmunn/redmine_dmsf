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
          when 'file', 'file-link'
            if item.deleted && (item.deleted > 0)
              super column, item, value
            else
              link_to h(value), dmsf_file_path(id: item.id)
            end
          when 'folder', 'folder-link'
            if(item.id)
              if item.deleted && (item.deleted > 0)
                super column, item, value
              else
                link_to h(value), edit_dmsf_path(id: item.project_id, folder_id: item.id)
              end
            else
              if item.deleted && (item.deleted > 0)
                super column, item, item.project_id
              else
                link_to h(item.project_id), edit_root_dmsf_path(id: item.project_id)
              end
             end
          else
            h(value)
          end
        when :author
          if value
            link_to "#{item.firstname} #{item.lastname}", user_path(id: value)
          else
            return super column, item, value
          end
        when :title
          case item.type
          when 'folder'
            if item.deleted && (item.deleted > 0)
              tag = content_tag('span', value, class: 'icon icon-folder')
            else
              tag = "<span class=\"dmsf_expander\" onclick=\"dmsfToggle('#{item.id}','#{item.id}span','#{escape_javascript(exp_folder_dmsf_path)}')\"></span>".html_safe +
              link_to(h(value),
                dmsf_folder_path(id: item.project_id, folder_id: item.id),
                class: 'icon icon-folder',
                title: h(value))
            end
            tag + content_tag('div', item.filename, class: 'dmsf_filename', title: l(:title_filename_for_download))
          when 'folder-link'
            if item.deleted && (item.deleted > 0)
              tag = content_tag('span', value, class: 'icon icon-folder')
            else
              tag = "<span class=\"dmsf_expander\"></span>".html_safe +
              link_to(h(value),
                      dmsf_folder_path(id: item.project_id, folder_id: item.id),
                      class: 'icon icon-folder',
                      title: h(value))
            end
            tag + content_tag('div', item.filename, class: 'dmsf_filename', title: l(:label_target_folder))
          when 'file', 'file-link'
            if item.deleted && (item.deleted > 0)
              tag = content_tag('span', value, class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}")
            else
              file_view_url = url_for({ controller: :dmsf_files, action: 'view', id: item.id })
              content_type = Redmine::MimeType.of(value)
              content_type = 'application/octet-stream' if content_type.blank?
              tag = "<span class=\"dmsf_expander\"></span>".html_safe +
              link_to(h(value),
                   file_view_url,
                   target: '_blank',
                   class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}",
                   title: h(value),
                   'data-downloadurl': "#{content_type}:#{h(value)}:#{file_view_url}")
            end
            tag + content_tag('div', item.filename, class: 'dmsf_filename', title: l(:title_filename_for_download))
          when 'url-link'
            if item.deleted && (item.deleted > 0)
              tag = content_tag('span', value, class: 'icon icon-link')
            else
              tag = "<span class=\"dmsf_expander\"></span>".html_safe +
                  link_to(h(value), item.filename, target: '_blank', class: 'icon icon-link')
            end
            tag + content_tag('div', item.filename, class: 'dmsf_filename', title: l(:field_url))
          else
            h(value)
          end
        when :size
          number_to_human_size(value)
        when :workflow
          if value
            if item.workflow_id && (!(item.deleted && (item.deleted > 0)))
              if item.type == 'file'
                url = log_dmsf_workflow_path(project_id: item.project_id, id: item.workflow_id, dmsf_file_id: item.id)
              else
                url = log_dmsf_workflow_path(project_id: item.project_id, id: item.workflow_id, dmsf_link_id: item.id)
              end
              link_to(h(DmsfWorkflow.workflow_str(value.to_i)), url, remote: true)
            else
              h(DmsfWorkflow.workflow_str(value.to_i))
            end
          else
            super column, item, value
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