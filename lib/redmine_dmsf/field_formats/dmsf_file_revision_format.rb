# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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
  module FieldFormats
    # Custom field type DmsfFileRevision
    class DmsfFileRevisionFormat < Redmine::FieldFormat::Unbounded
      add 'dmsf_file_revision'

      self.customized_class_names = nil
      self.multiple_supported = false
      self.bulk_edit_supported = false

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        member = Member.find_by(user_id: User.current.id, project_id: custom_value.customized.project.id)
        if member&.dmsf_fast_links?
          view.text_field_tag(tag_name, custom_value.value, options.merge(id: tag_id))
        else
          select_edit_tag(view, tag_id, tag_name, custom_value, options)
        end
      end

      def select_edit_tag(view, tag_id, tag_name, custom_value, options = {})
        blank_option = ''.html_safe
        if custom_value.custom_field.is_required?
          if custom_value.custom_field.default_value.blank?
            blank_option =
              view.content_tag(
                'option',
                "--- #{l(:actionview_instancetag_blank_option)} ---",
                value: ''
              )
          end
        else
          blank_option = view.content_tag('option', '&nbsp;'.html_safe, value: '')
        end
        options_tags =
          blank_option + view.options_for_select(possible_custom_value_options(custom_value), custom_value.value)
        view.select_tag(tag_name,
                        options_tags,
                        options.merge(id: tag_id, multiple: custom_value.custom_field.multiple?))
      end

      def possible_values_options(_custom_field, object = nil)
        options = []
        if object&.project
          files = object.project.dmsf_files.visible.to_a
          DmsfFolder.visible(false).where(project_id: object.project.id).find_each do |f|
            files += f.dmsf_files.visible.to_a
          end
          files.sort! { |a, b| a.title.casecmp(b.title) }
          options = files.map { |f| [f.name, f.last_revision.id.to_s] }
        end
        options
      end

      def formatted_value(view, _custom_field, value, _customized = nil, _html = false)
        return '' if value.blank?

        revision = DmsfFileRevision.find_by(id: value)
        unless revision &&
               User.current.allowed_to?(:view_dmsf_files, revision.dmsf_file.project) &&
               (revision.dmsf_file.dmsf_folder.nil? || revision.dmsf_file.dmsf_folder.visible?)
          return ''
        end

        member = Member.find_by(user_id: User.current.id, project_id: revision.dmsf_file.project.id)
        filename = revision.formatted_name(member)
        file_view_url = view.static_dmsf_file_path(revision.dmsf_file, download: revision, filename: filename)
        view.link_to(
          h(filename),
          file_view_url,
          target: '_blank',
          rel: 'noopener',
          class: "icon icon-file #{DmsfHelper.filetype_css(revision.dmsf_file.name)}",
          title: h(revision.try(:tooltip)),
          'data-downloadurl' => "#{revision.detect_content_type}:#{h(revision.dmsf_file.name)}:#{file_view_url}"
        )
      end
    end
  end
end
