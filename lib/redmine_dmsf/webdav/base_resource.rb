# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

require 'dav4rack'

module RedmineDmsf
  module Webdav
    class BaseResource < DAV4Rack::Resource
      include Redmine::I18n
      include ActionView::Helpers::NumberHelper

      def initialize(*args)
        webdav_setting = Setting.plugin_redmine_dmsf['dmsf_webdav']
        raise NotFound if !webdav_setting.nil? && webdav_setting.empty?
        super(*args)
      end

      DIR_FILE = "<tr><td class=\"name\"><a href=\"%s\">%s</a></td><td class=\"size\">%s</td><td class=\"type\">%s</td><td class=\"mtime\">%s</td></tr>"

      def accessor=(klass)
        @__proxy = klass
      end

      # Overridable function to provide better listing for GET requests
      def long_name
        nil
      end

      # Overridable function to provide better listing for GET requests
      def special_type
        nil
      end
      
      # Base attribute overriding in order to allow non-ascii characters in path
      def path
        @path.force_encoding('utf-8')
      end
      
      # Base attribute overriding in order to allow non-ascii characters in path
      def public_path
        @public_path.force_encoding('utf-8')
      end

      # Generate HTML for Get requests
      def html_display
        @response.body = ''
        Confict unless collection?        
        entities = children.map{|child| 
          DIR_FILE % [
            child.public_path, 
            child.long_name || child.name, 
            child.collection? ? '' : number_to_human_size(child.content_length),
            child.special_type || child.content_type, 
            child.last_modified
          ]
        } * "\n"
        entities = DIR_FILE % [
          parent.public_path,
          l(:parent_directory),
          '',
          '',
          '',
        ] + entities if parent        
        @response.body << index_page % [ path.empty? ? '/' : path, path.empty? ? '/' : path, entities ]
      end

      # Run method through proxy class - ensuring always compatible child is generated      
      def child(name)
        new_public = public_path.dup
        new_public = new_public + '/' unless new_public[-1,1] == '/'
        new_public = '/' + new_public unless new_public[0,1] == '/'
        new_path = path.dup
        new_path = new_path + '/' unless new_path[-1,1] == '/'
        new_path = '/' + new_path unless new_path[0,1] == '/'
        @__proxy.class.new("#{new_public}#{name}", "#{new_path}#{name}", request, response, options.merge(:user => @user))
      end

      def parent
        p = @__proxy.parent
        return nil if p.nil? 
        return p.resource.nil? ? p : p.resource
      end

      # Override index_page from DAV4Rack::Resource
      def index_page
        return <<-PAGE
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>  
  <title>Index of %s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
    table { width:100%%; }
    .name { text-align:left; }
    .size { text-align: center; }
    .type { text-align: center; width: 11em; }
    .mtime { width:15em; }
  </style>
</head>
<body>
  <h1>Index of %s</h1>
  <hr/>
  <table>
    <tr>
      <th class='name'>Name</th>
      <th class='size'>Size</th>
      <th class='type'>Type</th>
      <th class='mtime'>Last Modified</th>
    </tr>
  %s
  </table>
  <hr/>
</body>
</html>
        PAGE
      end

    protected
    
      def basename
        File.basename(path)
      end

      def dirname
        File.dirname(path)
      end

      # Return instance of Project based on path
      def project
        unless @project
          pinfo = @path.split('/').drop(1)
          if pinfo.length > 0
            begin
              @project = Project.find(pinfo.first)
            rescue Exception => e
              Rails.logger.error e.message
            end
          end
        end
        @project
      end

      # Make it easy to find the path without project in it.
      def projectless_path
        '/' + path.split('/').drop(2).join('/')
      end

      def path_prefix
        public_path.gsub(/#{Regexp.escape(path)}$/, '')        
      end
    end
  end
end