# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
#  Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

# Queries helper
module DmsfQueriesHelper
  include ApplicationHelper

  def column_value(column, item, value)
    return super column, item, value unless item.is_a? DmsfFolder

    case column.name
    when :modified
      val = super(column, item, value)
      case item.type
      when 'file'
        file = DmsfFile.find_by(id: item.id)
        if file&.locked?
          return content_tag(:span, val) +
                 content_tag(:span,
                             '',
                             title: l(:title_locked_by_user, user: file.locked_by),
                             class: 'icon icon-unlock dmsf-icon-unlock')
        end
      when 'folder'
        folder = DmsfFolder.find_by(id: item.id)
        if folder&.locked?
          return content_tag(:span, val) +
                 content_tag(:span,
                             '',
                             title: l(:title_locked_by_user, user: folder.locked_by),
                             class: 'icon icon-unlock dmsf-icon-unlock')
        end
      end
      content_tag(:span, val) +
        content_tag(:span, '', class: 'icon icon-none')
    when :id
      case item.type
      when 'file'
        if item&.deleted&.positive?
          h(value)
        else
          link_to h(value), dmsf_file_path(id: item.id)
        end
      when 'file-link'
        if item&.deleted&.positive?
          h(item.revision_id)
        else
          link_to h(item.revision_id), dmsf_file_path(id: item.revision_id)
        end
      when 'folder'
        if item.id
          if item&.deleted&.positive?
            h(value)
          else
            link_to h(value), edit_dmsf_path(id: item.project_id, folder_id: item.id)
          end
        elsif item&.deleted&.positive?
          h(item.project_id)
        else
          link_to h(item.project_id), edit_root_dmsf_path(id: item.project_id)
        end
      when 'folder-link'
        if item.id
          if item&.deleted&.positive?
            h(item.revision_id)
          else
            link_to h(item.revision_id), edit_dmsf_path(id: item.project_id, folder_id: item.revision_id)
          end
        elsif item&.deleted&.positive?
          h(item.project_id)
        else
          link_to h(item.project_id), edit_root_dmsf_path(id: item.project_id)
        end
      when 'project'
        link_to h(item.project_id), edit_root_dmsf_path(id: item.project_id)
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
        tag = h("[#{value}]")
        tag = if item.project.module_enabled?(:dmsf)
                link_to tag, dmsf_folder_path(id: item.project), class: 'icon icon-folder'
              else
                content_tag 'span', tag, class: 'icon icon-folder'
              end
        unless filter_any?
          path = expand_folder_dmsf_path
          columns = params['c']
          if columns.present?
            path << '?'
            path << columns.map { |col| "c[]=#{col}" }.join('&')
          end
          tag = content_tag(
            'span',
            '',
            class: 'dmsf-expander',
            onclick: "dmsfToggle(this, '#{item.id}', null,'#{escape_javascript(path)}')"
          ) + tag
          tag = content_tag('div', tag, class: 'row-control dmsf-row-control')
        end
        tag += content_tag('div', item.filename, class: 'dmsf-filename', title: l(:title_filename_for_download))
        if item.project.watched_by?(User.current)
          tag += link_to('',
                         watch_path(object_type: 'project', object_id: item.project.id),
                         title: l(:button_unwatch),
                         method: 'delete',
                         class: 'icon icon-fav')
        end
        tag
      when 'folder'
        if item&.deleted?
          tag = content_tag('span', value, class: 'icon icon-folder')
        else
          tag = link_to(h(value), dmsf_folder_path(id: item.project, folder_id: item.id), class: 'icon icon-folder')
          unless filter_any?
            path = expand_folder_dmsf_path
            columns = params['c']
            if columns.present?
              path << '?'
              path << columns.map { |col| "c[]=#{col}" }.join('&')
            end
            tag = content_tag(
              'span',
              '',
              class: 'dmsf-expander',
              onclick: "dmsfToggle(this, '#{item.project.id}', '#{item.id}','#{escape_javascript(path)}')"
            ) + tag
            tag = content_tag('div', tag, class: 'row-control dmsf-row-control')
          end
        end
        tag += content_tag('div', item.filename, class: 'dmsf-filename', title: l(:title_filename_for_download))
        if !item&.deleted? && item.watched_by?(User.current)
          tag += link_to('',
                         watch_path(object_type: 'dmsf_folder', object_id: item.id),
                         title: l(:button_unwatch),
                         method: 'delete',
                         class: 'icon icon-fav')
        end
        tag
      when 'folder-link'
        if item&.deleted?
          tag = content_tag('span', value, class: 'icon icon-folder')
        else
          # For links we use revision_id containing dmsf_folder.id in fact
          tag = link_to(h(value),
                        dmsf_folder_path(id: item.project, folder_id: item.revision_id),
                        class: 'icon icon-folder')
          tag = content_tag('span', '', class: 'dmsf-expander') + tag unless filter_any?
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:label_target_folder))
      when 'file', 'file-link'
        if item&.deleted?
          tag = content_tag('span', value, class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}")
        else
          # For links we use revision_id containing dmsf_file.id in fact
          file_view_url = url_for(
            { controller: :dmsf_files, action: 'view', id: item.type == 'file' ? item.id : item.revision_id }
          )
          content_type = Redmine::MimeType.of(item.filename)
          content_type = 'application/octet-stream' if content_type.blank?
          options = { class: "icon icon-file #{DmsfHelper.filetype_css(item.filename)}",
                      'data-downloadurl': "#{content_type}:#{h(value)}:#{file_view_url}" }
          unless previewable?(item.filename, content_type)
            options[:target] = '_blank'
            options[:rel] = 'noopener'
          end
          tag = link_to h(value), file_view_url, options
          tag = content_tag('span', '', class: 'dmsf-expander') + tag unless filter_any?
        end
        member = Member.find_by(user_id: User.current.id, project_id: item.project_id)
        revision = DmsfFileRevision.find_by(id: item.customized_id)
        filename = revision ? revision.formatted_name(member) : item.filename
        tag += content_tag('div', filename, class: 'dmsf-filename', title: l(:title_filename_for_download))
        if (item.type == 'file') && !item&.deleted? && revision.dmsf_file&.watched_by?(User.current)
          tag += link_to('',
                         watch_path(object_type: 'dmsf_file', object_id: item.id),
                         title: l(:button_unwatch),
                         method: 'delete',
                         class: 'icon icon-fav')
        end
        tag
      when 'url-link'
        if item&.deleted?
          tag = content_tag('span', value, class: 'icon dmsf-icon-link')
        else
          tag = link_to(h(value), item.filename, target: '_blank', rel: 'noopener', class: 'icon dmsf-icon-link')
          tag = content_tag('span', '', class: 'dmsf-expander') + tag unless filter_any?
        end
        tag + content_tag('div', item.filename, class: 'dmsf-filename', title: l(:field_url))
      else
        h(value)
      end
    when :size
      number_to_human_size value
    when :workflow
      if value
        if item.workflow_id && !item&.deleted?
          url = if item.type == 'file'
                  log_dmsf_workflow_path project_id: item.project_id, id: item.workflow_id, dmsf_file_id: item.id
                else
                  log_dmsf_workflow_path project_id: item.project_id, id: item.workflow_id, dmsf_link_id: item.id
                end
          text, names = DmsfWorkflow.workflow_info(item.workflow, item.workflow_id, item.revision_id)
          link_to h(text), url, remote: true, title: names
        else
          h(DmsfWorkflow.workflow_str(value.to_i))
        end
      else
        super column, item, value
      end
    when :comment
      value.present? ? content_tag('div', textilizable(value), class: 'wiki') : ''
    else
      super column, item, value
    end
  end

  def csv_value(column, object, value)
    case column.name
    when :size
      ActiveSupport::NumberHelper.number_to_human_size value
    when :workflow
      if value
        text, _names = DmsfWorkflow.workflow_info(object.workflow, object.workflow_id, object.revision_id)
        text
      else
        super column, object, value
      end
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
    # :v - value, :op - operator
    size = params[:op]&.keys&.size
    if size
      if (size == 1) && params[:op].key?('title') && params[:op]['title'] == '~' && params[:v]['title'].join.empty?
        return false
      end

      return true
    end
    false
  end

  def previewable?(filename, content_type)
    case content_type
    when 'text/markdown', 'text/x-textile'
      true
    else
      Redmine::MimeType.is_type?('text', filename) || Redmine::SyntaxHighlighting.filename_supported?(filename)
    end
  end
end
