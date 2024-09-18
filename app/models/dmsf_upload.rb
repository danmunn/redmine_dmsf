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

# Upload
class DmsfUpload
  attr_accessor :name, :disk_filename, :mime_type, :title, :description, :comment, :major_version, :minor_version,
                :patch_version, :locked, :workflow, :custom_values, :tempfile_path, :digest, :token
  attr_reader   :size

  def disk_file
    Rails.root.join 'tmp', disk_filename
  end

  def self.create_from_uploaded_attachment(project, folder, uploaded_file)
    a = Attachment.find_by_token(uploaded_file[:token]) if uploaded_file[:token].present?
    if a
      uploaded = {
        disk_filename: DmsfHelper.temp_filename(a.filename),
        content_type: a.content_type,
        original_filename: a.filename,
        comment: uploaded_file[:description],
        tempfile_path: a.diskfile,
        token: uploaded_file[:token],
        digest: a.digest
      }
      DmsfUpload.new project, folder, uploaded
    else
      Rails.logger.error "An attachment not found by its token: #{uploaded_file[:token]}"
      nil
    end
  end

  def initialize(project, folder = nil, uploaded = nil)
    unless uploaded
      @name = ''
      @disk_filename = ''
      @mime_type = ''
      @size = 0
      @tempfile_path = ''
      @token = ''
      @digest = ''
      if Setting.plugin_redmine_dmsf['empty_minor_version_by_default']
        @major_version = 1
        @minor_version = nil
      else
        @major_version = 0
        @minor_version = 0
      end
      @patch_version = nil
      @workflow = nil
      revision = DmsfFileRevision.new
      @custom_values = revision.custom_field_values
      return
    end

    @name = uploaded[:original_filename]

    file = DmsfFile.find_file_by_name(project, folder, @name)
    unless file
      link = DmsfLink.find_link_by_file_name(project, folder, @name)
      file = link.target_file if link
    end

    @disk_filename = uploaded[:disk_filename]
    @mime_type = uploaded[:content_type]
    @size = File.size?(uploaded[:tempfile_path])
    unless @size
      @size = 0
      Rails.logger.error "Cannot find #{uploaded[:tempfile_path]}"
    end
    @tempfile_path = uploaded[:tempfile_path]
    @token = uploaded[:token]
    @digest = uploaded[:digest]

    if file.nil? || file.last_revision.nil?
      @title = DmsfFileRevision.filename_to_title(@name)
      @description = uploaded[:comment]
      if Setting.plugin_redmine_dmsf['empty_minor_version_by_default']
        @major_version = 1
        @minor_version = nil
      else
        @major_version = 0
        @minor_version = 0
      end
      @patch_version = nil
      @workflow = nil
      file = DmsfFile.new
      file.project_id = project.id
      revision = DmsfFileRevision.new
      revision.dmsf_file = file
      @custom_values = revision.custom_field_values
    else
      last_revision = file.last_revision
      @title = last_revision.title
      if last_revision.description.present?
        @description = last_revision.description
        @comment = uploaded[:comment] if uploaded[:comment].present?
      elsif uploaded[:comment].present?
        @comment = uploaded[:comment]
      end
      @major_version = last_revision.major_version
      @minor_version = last_revision.minor_version
      @patch_version = last_revision.patch_version
      @workflow = last_revision.workflow
      @custom_values = Array.new(file.last_revision.custom_values)

      # Add default value for CFs not existing
      present_custom_fields = file.last_revision.custom_values.collect(&:custom_field).uniq
      file.last_revision.available_custom_fields.each do |cf|
        if cf.default_value && present_custom_fields.exclude?(cf)
          @custom_values << CustomValue.new({ custom_field: cf, value: cf.default_value })
        end
      end
    end
    @locked = file&.locked_for_user?
  end
end
