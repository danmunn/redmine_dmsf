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

  unless Redmine::Plugin.installed?('easy_extensions')

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

  def self.filetype_css(filename)
    extension = File.extname(filename)
    extension = extension[1, extension.length - 1]
    path = File.join(Redmine::Plugin.public_directory, ['redmine_dmsf', 'images', 'filetypes', "#{extension}.png"])
    cls = if File.exist?(path)
            +"filetype-#{extension}"
          else
            Redmine::MimeType.css_class_of filename
          end
    cls << ' dmsf-icon-file' if cls
    cls
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
end
