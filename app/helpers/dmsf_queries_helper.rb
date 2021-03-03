# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

module DmsfQueriesHelper
  include ApplicationHelper

  def column_value(column, item, value)
    unless item.is_a? DmsfFolder
      return super column, item, value
    end
    case column.name
    when :modified
      val = super(column, item, value)
      case item.type
      when 'file'
        file = DmsfFile.find_by(id: item.id)
        if file&.locked?
          return content_tag(:span, val) +
            content_tag(:span, '', title: l(:title_locked_by_user, user: file.locked_by), class: 'icon icon-unlock')
        end
      when 'folder'
        folder = DmsfFolder.find_by(id: item.id)
        if folder&.locked?
          return content_tag(:span, val) +
            content_tag(:span, '', title: l(:title_locked_by_user, user: folder.locked_by), class: 'icon icon-unlock')
        end
      end
      content_tag(:span, val) +
        content_tag(:span, '', class: 'icon icon-none')
    when :id
      case item.type
      when 'file', 'file-link'
        if item&.deleted > 0
          super column, item, value
        else
          link_to h(value), dmsf_file_path(id: item.id)
        end
      when 'folder', 'folder-link'
        if item.id
          if item&.deleted > 0
            super column, item, value
          else
            link_to h(value), edit_dmsf_path(id: item.project_id, folder_id: item.id)
          end
        else
          if item&.deleted > 0
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
        user = User.find_by(id: value)
        if user
          link_to user.name, user_path(id: value)
        else
          super column, item, value
        end
      else
        super column, item, value
      end
    when :title
      case item.type
      when 'project'
        tag = link_to(h("[#{value}]"), dmsf_folder_path(id: item.project), class: 'icon icon-folder')
        unless filter_any?
          tag = "<span class=\"dmsf_expander\" onclick=\"dmsfToggle(this, '#{item.id}', null,'#{escape_javascript(expand_folder_dmsf_path)}')\"></span>".html_safe + tag
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:title_filename_for_download))
      when 'folder'
        if item&.deleted > 0
          tag = content_tag('span', value, class: 'icon icon-folder')
        else
          tag = link_to(h(value), dmsf_folder_path(id: item.project, folder_id: item.id), class: 'icon icon-folder')
          unless filter_any?
            tag = "<span class=\"dmsf_expander\" onclick=\"dmsfToggle(this, '#{item.project.id}', '#{item.id}','#{escape_javascript(expand_folder_dmsf_path)}')\"></span>".html_safe + tag
          end
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:title_filename_for_download))
      when 'folder-link'
        if item&.deleted > 0
          tag = content_tag('span', value, class: 'icon icon-folder')
        else
          # For links we use revision_id containing dmsf_folder.id in fact
          tag = link_to(h(value), dmsf_folder_path(id: item.project, folder_id: item.revision_id), class: 'icon icon-folder')
          unless filter_any?
            tag = "<span class=\"dmsf_expander\"></span>".html_safe + tag
          end
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:label_target_folder))
      when 'file', 'file-link'
        if item&.deleted > 0
          tag = content_tag('span', value, class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}")
        else
          # For links we use revision_id containing dmsf_file.id in fact
          file_view_url = url_for({ controller: :dmsf_files, action: 'view', id: (item.type == 'file') ? item.id : item.revision_id })
          content_type = Redmine::MimeType.of(value)
          content_type = 'application/octet-stream' if content_type.blank?
          tag = link_to(h(value), file_view_url, target: '_blank',
            class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}",
            'data-downloadurl': "#{content_type}:#{h(value)}:#{file_view_url}")
          unless filter_any?
            tag = "<span class=\"dmsf_expander\"></span>".html_safe + tag
          end
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:title_filename_for_download))
      when 'url-link'
        if item&.deleted > 0
          tag = content_tag('span', value, class: 'icon icon-link')
        else
          tag = link_to(h(value), item.filename, target: '_blank', class: 'icon icon-link')
          unless filter_any?
            tag = "<span class=\"dmsf_expander\"></span>".html_safe + tag
          end
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:field_url))
      else
        h(value)
      end
    when :size
      number_to_human_size value
    when :workflow
      if value
        if item.workflow_id && (!(item&.deleted > 0))
          if item.type == 'file'
            url = log_dmsf_workflow_path(project_id: item.project_id, id: item.workflow_id, dmsf_file_id: item.id)
          else
            url = log_dmsf_workflow_path(project_id: item.project_id, id: item.workflow_id, dmsf_link_id: item.id)
          end
          link_to h(DmsfWorkflow.workflow_str(value.to_i)), url, remote: true
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

  def csv_value(column, object, value)
    case column.name
    when :size
      ActiveSupport::NumberHelper.number_to_human_size value
    when :workflow
      DmsfWorkflow.workflow_str value.to_i
    when :author
      if value
        user = User.find_by(id: value)
        if user
          user.name
        else
          super column, object, value
        end
      end
    else
      super column, object, value
    end
  end

  def filter_any?
    # :v - standard filters
    # :op - custom fields filters
    [:v, :op].each do |p|
      if params[p]
        params[p].each do |filter|
          return true if (filter.size > 1) && filter[1].all?{ |v| v.present? }
        end
      end
    end
    false
  end

end
