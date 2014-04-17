# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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
    if File.exists?("#{File.dirname(__FILE__)}/../../assets/images/filetypes/#{extension}.png")
      return "filetype-#{extension}";
    else
      return Redmine::MimeType.css_class_of(filename)
    end
  end

  def plugin_asset_path(plugin, asset_type, source)    
    return "#{Redmine::Utils.relative_url_root}/plugin_assets/#{plugin}/#{asset_type}/#{source}"           
  end

  def self.to_time(obj)
    #Right, enough of bugs, let's try a better approach here.
    return if !obj
    return obj.to_time(ActiveRecord::Base.default_timezone) if obj.is_a?(String)

    # Why can't Mysql::Time conform to time object? - without a utc? method it breaks redmine's
    # rendering method, so we convert it to string, and back into time - not the most efficient 
    # of methods - however seems functional. Not sure if MySQL
    return obj.to_s.to_time(ActiveRecord::Base.default_timezone) if obj.class.name == 'Mysql::Time'
    return obj
  end  
  
end
