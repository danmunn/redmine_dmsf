# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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
require 'digest/md5'

module DmsfHelper

  def self.temp_dir
    Dir.tmpdir
  end

  def self.temp_filename(filename)
    filename = sanitize_filename(filename)
    timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
    while File.exist?(File.join(temp_dir, "#{timestamp}_#{filename}"))
      timestamp.succ!
    end
    "#{timestamp}_#{filename}"
  end

  def self.sanitize_filename(filename)
    # get only the filename, not the whole path
    just_filename = File.basename(filename.gsub('\\\\', '/'))

    # replace all non alphanumeric, hyphens or periods with underscore
    just_filename = just_filename.gsub(/[^\w\.\-]/,'_')

    unless just_filename =~ %r{^[a-zA-Z0-9_\.\-]*$}
      # keep the extension if any
      extension = $1 if just_filename =~ %r{(\.[a-zA-Z0-9]+)$}
      just_filename = Digest::MD5.hexdigest(just_filename) << extension
    end

    just_filename
  end

  def self.filetype_css(filename)
    extension = File.extname(filename)
    extension = extension[1, extension.length-1]
    if File.exist?("#{File.dirname(__FILE__)}/../../assets/images/filetypes/#{extension}.png")
      "filetype-#{extension}";
    else
      Redmine::MimeType.css_class_of(filename)
    end
  end

  def plugin_asset_path(plugin, asset_type, source)
    "#{Redmine::Utils.relative_url_root}/plugin_assets/#{plugin}/#{asset_type}/#{source}"
  end

  def json_url
    if I18n.locale && !I18n.locale.to_s.match(/^en.*/)
      "jquery.dataTables/#{I18n.locale.to_s.downcase}.json"
    else
      'jquery.dataTables/en.json'
    end
  end

  def self.all_children_sorted(parent, pos, ident)
    # Folders && files && links
    nodes = parent.dmsf_folders.visible + parent.dmsf_links.visible + parent.dmsf_files.visible
    # Alphabetical and type sort
    nodes.sort! do |x, y|
      if ((x.is_a?(DmsfFolder) || (x.is_a?(DmsfLink) && x.is_folder?)) &&
            (y.is_a?(DmsfFile) || (y.is_a?(DmsfLink) && y.is_file?)))
        -1
      elsif ((x.is_a?(DmsfFile) || (x.is_a?(DmsfLink) && x.is_file?)) &&
            (y.is_a?(DmsfFolder) || (y.is_a?(DmsfLink) && y.is_folder?)))
        1
      else
        x.title.downcase <=> y.title.downcase
      end
    end
    # Calculate position
    step = 1.0 / (10 ** ident)
    tree = []
    i = 0
    nodes.each do |x|
      if x.is_a?(DmsfFolder) || (x.is_a?(DmsfLink) && x.is_folder?)
        i += 1
        tree << [x, pos + (step * i)]
      else
        tree << [x, pos + step + i]
      end
    end
    tree
  end

end
