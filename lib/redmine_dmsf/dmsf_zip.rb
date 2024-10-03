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

require 'zip'

module RedmineDmsf
  module DmsfZip
    # ZIP
    class Zip
      attr_reader :dmsf_files

      def initialize
        @temp_file = Tempfile.new(%w[dmsf_zip_ .zip], Rails.root.join('tmp'))
        @zip_file = ::Zip::OutputStream.open(@temp_file)
        @files = []
        @dmsf_files = []
        @folders = []
      end

      def read
        File.read @temp_file
      end

      def finish
        @zip_file.close
        @temp_file.path
      end

      def close
        @zip_file.close
      end

      def add_dmsf_file(dmsf_file, member = nil, root_path = nil, path = nil)
        unless dmsf_file&.last_revision && File.exist?(dmsf_file.last_revision.disk_file)
          raise RedmineDmsf::Errors::DmsfFileNotFoundError
        end

        if path
          string_path = path
        else
          string_path = dmsf_file.dmsf_folder.nil? ? '' : (dmsf_file.dmsf_folder.dmsf_path_str + File::SEPARATOR)
          string_path = string_path[(root_path.length + 1)..string_path.length] if root_path
        end
        string_path += dmsf_file.formatted_name(member)

        return if @files.include?(string_path)

        zip_entry = ::Zip::Entry.new(@zip_file, string_path, nil, nil, nil, nil, nil, nil,
                                     ::Zip::DOSTime.at(dmsf_file.last_revision.updated_at))
        @zip_file.put_next_entry zip_entry
        File.open(dmsf_file.last_revision.disk_file, 'rb') do |f|
          while (buffer = f.read(8192))
            @zip_file.write buffer
          end
        end
        @files << string_path
        @dmsf_files << dmsf_file
      end

      def add_attachment(attachment, path)
        return if @files.include?(path)

        raise RedmineDmsf::Errors::DmsfFileNotFoundError unless File.exist?(attachment.diskfile)

        zip_entry = ::Zip::Entry.new(@zip_file, path, nil, nil, nil, nil, nil, nil,
                                     ::Zip::DOSTime.at(attachment.created_on))
        @zip_file.put_next_entry zip_entry
        File.open(attachment.diskfile, 'rb') do |f|
          while (buffer = f.read(8192))
            @zip_file.write buffer
          end
        end
        @files << path
      end

      def add_raw_file(filename, data)
        return if @files.include?(filename)

        zip_entry = ::Zip::Entry.new(@zip_file, filename, nil, nil, nil, nil, nil, nil, ::Zip::DOSTime.now)
        @zip_file.put_next_entry zip_entry
        @zip_file.write data
        @files << filename
      end

      def add_dmsf_folder(dmsf_folder, member, root_path = nil)
        string_path = dmsf_folder.dmsf_path_str + File::SEPARATOR
        string_path = string_path[(root_path.length + 1)..string_path.length] if root_path
        zip_entry = ::Zip::Entry.new(@zip_file, string_path, nil, nil, nil, nil, nil, nil,
                                     ::Zip::DOSTime.at(dmsf_folder.modified))
        return if @folders.include?(string_path)

        @zip_file.put_next_entry zip_entry
        @folders << string_path
        dmsf_folder.dmsf_folders.visible.each { |folder| add_dmsf_folder(folder, member, root_path) }
        dmsf_folder.dmsf_files.visible.each { |file| add_dmsf_file(file, member, root_path) }
      end
    end
  end
end
