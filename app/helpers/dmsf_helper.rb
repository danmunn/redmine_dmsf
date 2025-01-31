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

require 'tmpdir'
require 'csv'

# DMSF helper
module DmsfHelper
  include Redmine::I18n

  unless defined?(EasyExtensions)

    def late_javascript_tag(content_or_options_with_block = nil, html_options = {}, &block)
      javascript_tag content_or_options_with_block, html_options, &block
    end

  end

  def self.temp_filename(filename)
    filename = sanitize_filename(filename)
    timestamp = DateTime.current.strftime('%y%m%d%H%M%S')
    timestamp.succ! while Rails.root.join("tmp/#{timestamp}_#{filename}").exist?
    "#{timestamp}_#{filename}"
  end

  def self.sanitize_filename(filename)
    # Get only the filename, not the whole path
    just_filename = File.basename(filename.gsub('\\\\', '/'))
    # Replace all non alphanumeric, hyphens or periods with underscore
    just_filename.gsub!(/[^\w.\-]/, '_')
    # Keep the extension if any
    if !/^[a-zA-Z0-9_.\-]*$/.match?(just_filename) && just_filename =~ /(.[a-zA-Z0-9]+)$/
      extension = Regexp.last_match(1)
      just_filename = Digest::SHA256.hexdigest(just_filename) << extension
    end
    just_filename
  end

  def plugin_asset_path(plugin, asset_type, source)
    File.join('/plugin_assets', plugin.to_s, asset_type, source)
  end

  def render_principals_for_new_email(users)
    principals_check_box_tags 'user_ids[]', users
  end

  def webdav_url(project, folder)
    url = ["#{Setting.protocol}:/", Setting.host_name, 'dmsf', 'webdav']
    if project
      url << ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(project))
      if folder
        folders = []
        while folder
          folders << folder
          folder = folder.dmsf_folder
        end
        folders.reverse_each do |f|
          url << f.title
        end
      end
    end
    url << ''
    url.join '/'
  end

  # Downloads zipped files securely by sanitizing the params[:entry]. Characters considered unsafe
  # are replaced with a underscore. The file_path is joined with File.join instead of Rails.root.join to eliminate
  # the risk of overriding the absolute path (Rails.root/tmp) with file_name when given as absoulte path too. This
  # makes the path double secure.
  def email_entry_tmp_file_path(entry)
    sanitized_entry = DmsfHelper.sanitize_filename(entry)
    file_name = "#{RedmineDmsf::DmsfZip::FILE_PREFIX}#{sanitized_entry}.zip"
    # rubocop:disable Rails/FilePath
    File.join(Rails.root.to_s, 'tmp', file_name)
    # rubocop:enable Rails/FilePath
  end

  # Extracts the variable part of the temp file name to be used as identifier in the
  # download email entries route.
  def tmp_entry_identifier(zipped_content)
    path = Pathname.new(zipped_content)
    zipped_file = path.basename(path.extname).to_s
    zipped_file.delete_prefix(RedmineDmsf::DmsfZip::FILE_PREFIX)
  end
end
