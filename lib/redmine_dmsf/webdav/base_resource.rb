# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

require 'addressable/uri'

module RedmineDmsf
  module Webdav
    # Base resource
    class BaseResource < Dav4rack::Resource
      include Redmine::I18n
      include ActionView::Helpers::NumberHelper

      attr_reader :public_path

      DIR_FILE = %(
                    <tr>
                      <td class="name"><a href="%s">%s</a></td>
                      <td class="size">%s</td>
                      <td class="type">%s</td>
                      <td class="mtime">%s</td>
                    </tr>
                   )

      def initialize(path, request, response, options)
        raise NotFound if Setting.plugin_redmine_dmsf['dmsf_webdav'].blank?

        @project = nil
        @public_path = "#{options[:root_uri_path]}#{path}"
        @children = nil
        super path, request, response, options
      end

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
        %(
          <!DOCTYPE html>
          <html lang="#{current_language}">
            <head>
              <title>%s</title>
              <meta http-equiv="content-type" content="text/html; charset=utf-8">
            </head>
            <body>
              <h1>%s</h1>
              <hr>
              <table>
                <tr>
                  <th class="name">#{l(:field_name)}</th>
                  <th class="size">#{l(:field_filesize)}</th>
                  <th class="type">#{l(:field_type)}</th>
                  <th class="mtime">#{l(:link_modified)}</th>
                </tr>
                %s
              </table>
              <hr>
           </body>
          </html>
        )
      end

      # Generate HTML for Get requests, or Head requests if no_body is true
      def html_display
        @response.body = +''
        Confict unless collection?
        entities = children.map do |child|
          format(DIR_FILE,
                 uri_encode(request.url_for(child.path)),
                 child.long_name || child.name,
                 child.collection? ? '' : number_to_human_size(child.content_length),
                 child.special_type || child.content_type,
                 child.last_modified)
        end
        entities *= "\n"
        if parent
          entities = format(DIR_FILE,
                            uri_encode(request.url_for(parent.path)),
                            l(:parent_directory),
                            '',
                            '',
                            '') + entities
        end
        @response.body << format(index_page, @path.empty? ? '/' : @path, @path.empty? ? '/' : @path, entities)
      end

      # Run method through proxy class - ensuring always compatible child is generated
      def child(name)
        new_path = normalized_path
        ResourceProxy.new "#{new_path}#{name}", request, response, @options.merge(user: @user)
      end

      def child_project(project)
        project_display_name = ProjectResource.create_project_name(project)
        new_path = normalized_path
        new_path += project_display_name
        ResourceProxy.new new_path, request, response, @options.merge(user: @user, project: true)
      end

      def parent
        p = @__proxy.parent
        return nil unless p

        p.resource.nil? ? p : p.resource
      end

      def options(_request, response)
        response['Allow'] ||= 'OPTIONS,HEAD,GET,PROPFIND' if @__proxy.read_only
        OK
      end

      def project
        resource_info
        @project
      end

      def subproject
        resource_info
        @subproject
      end

      def folder
        resource_info
        @folder
      end

      def file
        resource_info
        @file
      end

      class << self
        def get_project(scope, name, parent_project)
          prj = nil
          scope = scope.where(parent_id: parent_project.id) if parent_project
          if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
            if name =~ /^\[?.+ (\d+)\]?$/
              prj = scope.find_by(id: Regexp.last_match(1))
              # Check again whether it's really the project and not a folder with a number as a suffix
              prj = nil if prj && !name.start_with?("[#{DmsfFolder.get_valid_title(prj.name)}")
            end
          else
            identifier = if name.start_with?('[') && name.end_with?(']')
                           name[1..-2]
                         else
                           name
                         end
            prj = scope.find_by(identifier: identifier)
          end
          prj
        end
      end

      protected

      # Add slash at the beginning and the end if missing
      def normalized_path
        new_path = @path
        new_path << '/' unless new_path.end_with?('/')
        new_path.start_with?('/') ? new_path : new_path.insert(0, '/')
      end

      def uri_encode(uri)
        uri.gsub(/[()&\[\]]/, '(' => '%28', ')' => '%29', '&' => '%26', '[' => '%5B', ']' => '5D')
      end

      def basename
        File.basename @path
      end

      def path_prefix
        @public_path.gsub(/#{Regexp.escape(path)}$/, '')
      end

      def load_projects(project_scope)
        scope = project_scope.visible
        scope = scope.non_templates if scope.respond_to?(:non_templates)
        scope.find_each do |p|
          @children << child_project(p) if p.dmsf_available?
        end
      end

      # Adds the given xml namespace to namespaces and returns the prefix
      def add_namespace(namespace, prefix = "unknown#{rand 65_536}")
        @__proxy.add_namespace namespace, prefix
      end

      # returns the prefix for the given namespace, adding it if necessary
      def prefix_for(ns_href)
        @__proxy.prefix_for ns_href
      end

      private

      def resource_info
        return if @project # We have already got it

        pinfo = @path.split('/').drop(1)
        i = 1
        project_scope = Project.visible
        project_scope = project_scope.non_templates if project_scope.respond_to?(:non_templates)
        until pinfo.empty?
          prj = BaseResource.get_project(project_scope, pinfo.first, @project)
          if prj
            @project = prj
            if pinfo.length == 1
              @subproject = @project
              break # We're at the end
            end
          else
            @subproject = nil
            fld = get_folder(pinfo.first)
            if fld
              @folder = fld
            else
              @file = DmsfFile.find_file_by_name(@project, @folder, pinfo.first)
              @folder = nil
              unless pinfo.length < 2 || @file
                Rails.logger.error "Resource not found: #{@path}"
                raise Conflict
              end
              break # We're at the end
            end
          end
          i += 1
          pinfo = path.split('/').drop(i)
        end
      end

      def get_folder(name)
        return nil unless @project

        f = DmsfFolder.visible.find_by(project_id: @project.id, dmsf_folder_id: @folder&.id, title: name)
        f && !DmsfFolder.permissions?(f, allow_system: false) ? nil : f
      end
    end
  end
end
