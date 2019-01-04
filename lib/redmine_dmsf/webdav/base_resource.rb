# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

      attr_reader :public_path

      def initialize(path, request, response, options)
        @project = nil
        @public_path = "#{options[:root_uri_path]}#{path}"
        super(path, request, response, options)
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

      # Generate HTML for Get requests, or Head requests if no_body is true
      def html_display
        @response.body = ''
        Confict unless collection?        
        entities = children.map{|child| 
          DIR_FILE % [
            "#{@options[:root_uri_path]}#{child.path}",
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
        @response.body << index_page % [ @path.empty? ? '/' : @path, @path.empty? ? '/' : @path, entities ]
      end

      # Run method through proxy class - ensuring always compatible child is generated      
      def child(name)
        new_path = @path.dup
        new_path = new_path + '/' unless new_path[-1,1] == '/'
        new_path = '/' + new_path unless new_path[0,1] == '/'
        @__proxy.class.new("#{new_path}#{name}", request, response, @options.merge(:user => @user))
      end
      
      def child_project(p)
        project_display_name = ProjectResource.create_project_name(p)
        new_path = @path.dup
        new_path = new_path + '/' unless new_path[-1,1] == '/'
        new_path = '/' + new_path unless new_path[0,1] == '/'
        new_path += project_display_name
        @__proxy.class.new(new_path, request, response, @options.merge(:user => @user))
      end

      def parent
        p = @__proxy.parent
        return nil unless p
        p.resource.nil? ? p : p.resource
      end

      def options(request, response)
        return NotFound if ((@path.length > 1) && ((!project) || (!project.module_enabled?('dmsf'))))
        if @__proxy.read_only
          response['Allow'] ||= 'OPTIONS,HEAD,GET,PROPFIND'
        end
        OK
      end

    protected
    
      def basename
        File.basename(@path)
      end

      # Return instance of Project based on the path
      def project
        unless @project
          pinfo = @path.split('/').drop(1)
          if pinfo.length > 0
            if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
              if pinfo.first =~ /(\d+)$/
                @project = Project.find_by(id: $1)
                Rails.logger.error("No project found on path '#{@path}'") unless @project
              end
            else
              begin
                @project = Project.find(pinfo.first)
              rescue Exception => e
                Rails.logger.error e.message
              end
            end
          end
        end
        @project
      end

      # Make it easy to find the path without project in it.
      def projectless_path
        '/' + @path.split('/').drop(2).join('/')
      end

      def path_prefix
        @public_path.gsub(/#{Regexp.escape(path)}$/, '')
      end

    end
  end
end
