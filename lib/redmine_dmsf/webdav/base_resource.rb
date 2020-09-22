# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

require 'dav4rack'
require 'addressable/uri'

module RedmineDmsf
  module Webdav

    class BaseResource < DAV4Rack::Resource
      include Redmine::I18n
      include ActionView::Helpers::NumberHelper

      attr_reader :public_path

      def initialize(path, request, response, options)
        raise NotFound if Setting.plugin_redmine_dmsf['dmsf_webdav'].blank?
        @project = nil
        @public_path = "#{options[:root_uri_path]}#{path}"
        @children = nil
        super path, request, response, options
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

      # Overridden
      def index_page
        %{
          <!DOCTYPE html>
          <html lang="#{current_language}">
            <head>
              <title>%s</title>
              <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
            </head>
            <body>
              <h1>%s</h1>
              <hr/>
              <table>
                <tr>
                  <th class="name">#{l(:field_name)}</th>
                  <th class="size">#{l(:field_filesize)}</th>
                  <th class="type">#{l(:field_type)}</th>
                  <th class="mtime">#{l(:link_modified)}</th>
                </tr>
                %s
              </table>
              <hr/>
           </body>
          </html>
        }
      end

      # Generate HTML for Get requests, or Head requests if no_body is true
      def html_display
        @response.body = +''
        Confict unless collection?
        entities = children.map{ |child|
          DIR_FILE % [
            "#{@options[:root_uri_path]}#{Addressable::URI.encode(child.path)}",
            child.long_name || child.name, 
            child.collection? ? '' : number_to_human_size(child.content_length),
            child.special_type || child.content_type, 
            child.last_modified
          ]
        } * "\n"
        entities = DIR_FILE % [
            Addressable::URI.encode(parent.public_path),
          l(:parent_directory),
          '',
          '',
          '',
        ] + entities if parent        
        @response.body << index_page % [ @path.empty? ? '/' : @path, @path.empty? ? '/' : @path, entities ]
      end

      # Run method through proxy class - ensuring always compatible child is generated      
      def child(name)
        new_path = @path
        new_path = new_path + '/' unless new_path[-1,1] == '/'
        new_path = '/' + new_path unless new_path[0,1] == '/'
        @__proxy.class.new "#{new_path}#{name}", request, response, @options.merge(user: @user)
      end
      
      def child_project(p)
        project_display_name = ProjectResource.create_project_name(p)
        new_path = @path
        new_path = new_path + '/' unless new_path[-1,1] == '/'
        new_path = '/' + new_path unless new_path[0,1] == '/'
        new_path += project_display_name
        @__proxy.class.new new_path, request, response, @options.merge(user: @user)
      end

      def parent
        p = @__proxy.parent
        return nil unless p
        p.resource.nil? ? p : p.resource
      end

      def options(request, response)
        if @__proxy.read_only
          response['Allow'] ||= 'OPTIONS,HEAD,GET,PROPFIND'
        end
        OK
      end

    protected
    
      def basename
        File.basename @path
      end

      # Return instance of Project based on the path
      def project
        unless @project
          i = 1
          project_names = Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
          while true
            prj = nil
            pinfo = @path.split('/').drop(i)
            if pinfo.length > 0
              if project_names
                if pinfo.first =~ / (\d+)$/
                  prj = Project.visible.find_by(id: $1)
                  if prj
                    # Check again whether it's really the project and not a folder with a number as a suffix
                    prj = nil unless pinfo.first =~ /^#{DmsfFolder::get_valid_title(prj.name)}/
                  end
                end
              else
                prj = Project.visible.find_by(identifier: pinfo.first)
              end
            end
            break unless prj
            i = i + 1
            @project = prj
          end
        end
        @project
      end

      # Make it easy to find the path without project in it.
      def projectless_path
        i = 1
        project_names = Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
        while true
          prj = nil
          pinfo = @path.split('/').drop(i)
          if pinfo.length > 0
            if project_names
              if pinfo.first =~ / (\d+)$/
                prj = Project.visible.find_by(id: $1)
                if prj
                  # Check again whether it's really the project and not a folder with a number as a suffix
                  prj = nil unless pinfo.first =~ /^#{DmsfFolder::get_valid_title(prj.name)}/
                end
              end
            else
              prj = Project.visible.find_by(identifier: pinfo.first)
            end
          end
          return '/' + @path.split('/').drop(i).join('/') unless prj
          i = i + 1
        end
      end

      def path_prefix
        @public_path.gsub /#{Regexp.escape(path)}$/, ''
      end

      def load_projects(project_scope)
        project_scope.visible.find_each do |p|
            @children << child_project(p)
        end
      end

    end
  end
end
