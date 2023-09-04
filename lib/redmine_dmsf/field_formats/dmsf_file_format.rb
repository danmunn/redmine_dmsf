# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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
    # Custom field type DmsfFile
    class DmsfFileFormat < Redmine::FieldFormat::RecordList
      add 'dmsf_file'

      self.customized_class_names = nil
      self.multiple_supported = false
      self.bulk_edit_supported = false

      def possible_values_options(_custom_field, object = nil)
        options = []
        if object&.project
          files = object.project.dmsf_files.visible.to_a
          object.project.dmsf_folders.visible.each do |f|
            files += f.dmsf_files.visible.to_a
          end
          files.sort! { |a, b| a.title.casecmp(b.title) }
          options = files.map { |f| [f.name, f.id.to_s] }
        end
        options
      end

      def formatted_value(view, _custom_field, value, _customized: nil, _html: false)
        return '' if value.blank?

        dmsf_file = DmsfFile.find_by(id: value)
        return '' unless dmsf_file

        file_view_url = view.url_for({ controller: :dmsf_files, action: 'view', id: dmsf_file })
        view.link_to(
          h(dmsf_file.title),
          file_view_url,
          target: '_blank',
          rel: 'noopener',
          class: "icon icon-file #{DmsfHelper.filetype_css(dmsf_file.name)}",
          title: h(dmsf_file.last_revision.try(:tooltip)),
          'data-downloadurl' => "#{dmsf_file.last_revision.detect_content_type}:#{h(dmsf_file.name)}:#{file_view_url}"
        )
      end
    end
  end
end
