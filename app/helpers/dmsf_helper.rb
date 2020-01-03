# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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

  def json_url
    locale = I18n.locale || 'en'
    ret = File.join('jquery.dataTables', 'locales', "#{locale}.json")
    path = File.join('public', plugin_asset_path(:redmine_dmsf, 'javascripts', ret))
    unless File.exist?(path)
      Rails.logger.warn "#{path} not found"
      ret = File.join('jquery.dataTables', 'locales', 'en.json')
    end
    ret
  end

  def js_url
    locale = I18n.locale || 'en'
    ret = File.join('plupload', 'js', 'i18n', "#{locale}.js")
    path = File.join('public', plugin_asset_path(:redmine_dmsf, 'javascripts', ret))
    unless File.exist?(path)
      Rails.logger.warn "#{path} not found"
      ret = File.join('plupload', 'js', 'i18n', 'en.js')
    end
    ret
  end

  def all_children_sorted(parent, pos, ident)
    # Folders && files && links
    nodes = DmsfFolder::visible_folders(parent.dmsf_folders.visible.to_a, parent.is_a?(Project) ? parent : parent.project) +
        parent.dmsf_links.visible + parent.dmsf_files.visible
    # Alphabetical and type sort
    nodes.sort! do |x, y|
      if (x.is_a?(DmsfFolder) || (x.is_a?(DmsfLink) && x.is_folder?)) &&
            (y.is_a?(DmsfFile) || (y.is_a?(DmsfLink) && y.is_file?))
        -1
      elsif (x.is_a?(DmsfFile) || (x.is_a?(DmsfLink) && x.is_file?)) &&
            (y.is_a?(DmsfFolder) || (y.is_a?(DmsfLink) && y.is_folder?))
        1
      else
        clear_title(x.title) <=> clear_title(y.title)
      end
    end
    # Calculate position
    ident = 0 unless ident
    pos = (10 ** 12) unless pos
    step = (10 ** 12) / (10 ** (ident * 3))
    tree = []
    i = 0
    nodes.each do |x|
      if x.is_a?(DmsfFolder) || (x.is_a?(DmsfLink) && x.is_folder?)
        i += 1
        tree << [x, pos + (step * i)]
      else
        tree << [x, pos + (step * (i + 1))]
      end
    end
    tree
  end

  def self.dmsf_to_csv(parent, columns)
    CSV.generate(:force_quotes => true, :encoding => 'UTF-8') do |csv|
      # Header
      csv << columns.map { |c| c.capitalize }
      # Lines
      DmsfHelper.object_to_csv(csv, parent, columns)
    end
  end

  def self.object_to_csv(csv, parent, columns, level = -1)
    # Folder
    if level >= 0
      csv << parent.to_csv(columns, level)
    end
    # Sub-folders
    folders = parent.dmsf_folders.visible.to_a
    folders.concat(parent.folder_links.visible.to_a.map{ |l| l.folder })
    folders.compact!
    folders.sort!{ |x, y| x.title <=> y.title}
    folders.each do |f|
      DmsfHelper.object_to_csv(csv, f, columns, level + 1)
    end
    # Files
    files = parent.dmsf_files.visible.to_a
    files.concat(parent.file_links.visible.to_a.map{ |l| l.target_file })
    files.concat(parent.url_links.visible.to_a)
    files.compact!
    files.sort!{ |x, y| x.title <=> y.title}
    files.each do |file_or_link|
      csv << file_or_link.to_csv(columns, level + 1)
    end
  end

  def render_principals_for_new_email(users)
    principals_check_box_tags 'user_ids[]', users
  end

  # Replace specifics characters with their ASCII version + 'z' in order to fix the wrong ordering
  # e.g. 'č' -> 'cz'
  def clear_title(title)
    str = title.gsub(/[ěščřýáíéůúďťňĚŠČŘÝÁÍÉÚŮĎŤŇ]/) { |c| c + 'z' }
    str.tr('ěščřýáíéůúďťňĚŠČŘÝÁÍÉÚŮĎŤŇ', 'escryaieuudtnESCRYAIEUUDTN').downcase
  end

end
