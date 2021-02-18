# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

module RedmineDmsf
  module Webdav
    class ProjectResource < BaseResource
      include Redmine::I18n

      def children
        unless @children          
          @children = []
          if project
            # Sub-projects
            load_projects(project.children) if Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders']
            if project.module_enabled?(:dmsf)
              # Folders
              if User.current.allowed_to?(:view_dmsf_folders, project)
                project.dmsf_folders.visible.pluck(:title).each do |title|
                  @children.push child(title)
                end
              end
              # Files
              if User.current.allowed_to?(:view_dmsf_files, project)
                project.dmsf_files.visible.pluck(:name).each do |name|
                  @children.push child(name)
                end
              end
            end
          end
        end
        @children
      end      

      def exist?
        project&.visible?
      end

      def collection?
        true
      end

      def creation_date
        project&.created_on
      end

      def last_modified
        project&.updated_on
      end

      def etag
        sprintf '%x-%x-%x', 0, 4096, (last_modified ? last_modified.to_i : 0)
      end

      def name
        ProjectResource.create_project_name(project)
      end

      def long_name
        "[#{project&.name}]"
      end

      def content_type
        'inode/directory'
      end

      def special_type
        l(:field_project)
      end

      def content_length
        4096
      end

      def get(request, response)
        html_display
        response['Content-Length'] = response.body.bytesize.to_s
        response['Content-Type'] = 'text/html'
        OK
      end

      def make_collection
         MethodNotAllowed
      end

      def move(dest, overwrite)
        MethodNotAllowed
      end

      def delete
        MethodNotAllowed
      end

      def lock(args)
        e = DAV4Rack::LockFailure.new
        e.add_failure @path, MethodNotAllowed
        raise e
      end

      def self.create_project_name(prj)
        if prj
          if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
            "[#{DmsfFolder::get_valid_title(prj.name)} #{prj.id}]"
          else
            "[#{prj.identifier}]"
          end
        end
      end

    end
  end

end
