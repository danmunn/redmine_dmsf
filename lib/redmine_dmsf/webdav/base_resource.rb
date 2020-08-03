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

module RedmineDmsf
  module Webdav
    class BaseResource < DAV4Rack::Resource
      include Redmine::I18n
      include ActionView::Helpers::NumberHelper

      attr_reader :public_path

      def initialize(path, request, response, options)
        if Setting.plugin_redmine_dmsf['dmsf_webdav'].blank?
          raise NotFound
        end
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

      # Generate HTML for Get requests, or Head requests if no_body is true
      def html_display
        @response.body = +''
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
        if ((@path.length > 1) && ((!project) || (!project.module_enabled?('dmsf'))))
          return NotFound
        end
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
          while true
            pinfo = @path.split('/').drop(i)
            if pinfo.length > 0
              if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
                if pinfo.first =~ /(\d+)$/
                  prj = Project.visible.find_by(id: $1)
                  Rails.logger.error("No project found on path '#{@path}'") unless prj
                end
              else
                begin
                  scope = Project.visible.where(identifier: pinfo.first)
                  scope = scope.where(parent_id: @project.id) if @project
                  prj = scope.first
                rescue => e
                  Rails.logger.error e.message
                end
              end
            end
            break unless prj
            i = i + 1
            @project = prj
            prj = nil
          end
        end
        @project
      end

      # Make it easy to find the path without project in it.
      def projectless_path
        # TODO:
        '/' + @path.split('/').drop(2).join('/')
      end

      def path_prefix
        @public_path.gsub /#{Regexp.escape(path)}$/, ''
      end

      def load_projects(project_scope)
        project_scope
            .where.not(status: Project::STATUS_ARCHIVED)
            .find_each do |p|
          if dmsf_visible?(p) || dmsf_enabled?(p)
            @children << child_project(p)
          end
        end
      end

      private

      def dmsf_enabled?(prj)
        prj.module_enabled?(:dmsf) && Project.allowed_to_condition(User.current, :view_dmsf_folders)
      end

      def dmsf_visible?(prj)
        Rails.cache.fetch("#{prj.cache_key_with_version}/dmsf-visible", expires_in: 12.hours) do
          dmsf_visible_recursive? prj
        end
      end

      def dmsf_visible_recursive?(prj)
        prj.children.each do |p|
          if dmsf_enabled?(p)
            return true
          else
            return dmsf_visible?(p)
          end
        end
        false
      end

    end
  end
end
