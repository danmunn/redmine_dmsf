# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
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

require 'tmpdir'
require 'digest'
require 'csv'

module DmsfHelper
  include Redmine::I18n

  def self.temp_dir
    if Setting.plugin_redmine_dmsf['dmsf_tmpdir'].present?
      tmpdir = Pathname.new(Setting.plugin_redmine_dmsf['dmsf_tmpdir'])
    else
      tmpdir = Pathname.new(Dir.tmpdir)
    end
    tmpdir
  end

  def self.temp_filename(filename)
    filename = sanitize_filename(filename)
    timestamp = DateTime.current.strftime('%y%m%d%H%M%S')
    while temp_dir.join("#{timestamp}_#{filename}").exist?
      timestamp.succ!
    end
    "#{timestamp}_#{filename}"
  end

  def self.sanitize_filename(filename)
    # get only the filename, not the whole path
    just_filename = File.basename(filename.gsub('\\\\', '/'))
    # replace all non alphanumeric, hyphens or periods with underscore
    just_filename.gsub!(/[^\w\.\-]/, '_')
    unless %r{^[a-zA-Z0-9_\.\-]*$}.match?(just_filename)
      # keep the extension if any
      if just_filename =~ %r{(\.[a-zA-Z0-9]+)$}
        extension = $1
        just_filename = Digest::SHA256.hexdigest(just_filename) << extension
      end
    end
    just_filename
  end

  def self.filetype_css(filename)
    extension = File.extname(filename)
    extension = extension[1, extension.length-1]
    path = File.join(Redmine::Plugin.public_directory, ['redmine_dmsf', 'images', 'filetypes', "#{extension}.png"])
    if File.exist?(path)
      cls = +"filetype-#{extension}";
    else
      cls = Redmine::MimeType.css_class_of(filename)
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
        folders = [ ]
        while folder do
          folders << folder
          folder = folder.dmsf_folder
        end
        folders.reverse.each do |folder|
          url << folder.title
        end
      end
    end
    url << ''
    url.join '/'
  end

end
