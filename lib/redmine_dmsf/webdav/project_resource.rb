# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

      def initialize(*args)
        super(*args)
        @children = nil
      end
      
      def children
        unless @children          
          @children = []
          if project
            project.dmsf_folders.select(:title).visible.map do |p|
              @children.push child(p.title)
            end
            project.dmsf_files.select(:name).visible.map do |p|
              @children.push child(p.name)              
            end
          end
        end
        @children
      end      

      def exist?
        return false if (project.nil? || User.current.anonymous?)                        
        return false unless project.module_enabled?('dmsf')        
        User.current.admin? || User.current.allowed_to?(:view_dmsf_folders, project)
      end

      def really_exist?
        return false if project.nil?
        return false unless project.module_enabled?('dmsf')    
        true
      end

      def collection?
        exist?
      end

      def creation_date
        project.created_on unless project.nil?
      end

      def last_modified
        project.updated_on unless project.nil?
      end

      def etag
        sprintf('%x-%x-%x', 0, 4096, last_modified.to_i)
      end

      def name
        ProjectResource.create_project_name(project)
      end

      def long_name
        project.name unless project.nil?
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
        OK
      end

      def folder
        nil
      end

      def file
        nil
      end
      
      # Available properties
      def properties
        %w(creationdate displayname getlastmodified getetag resourcetype getcontenttype getcontentlength supportedlock lockdiscovery).collect do |prop|
          {:name => prop, :ns_href => 'DAV:'}
        end
      end

      def project_id
	      self.project.id if self.project
      end
      
      # Characters that MATCH this regex will be replaced with dots, no more than one dot in a row.
      INVALID_CHARACTERS = /[\/\\\?":<>#%\*]/.freeze # = / \ ? " : < > # % *

      def self.create_project_name(p)
        use_project_names = Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
        if use_project_names
          # 1. Invalid characters are replaced with a dot.
          # 2. Two or more dots in a row are replaced with a single dot.
          # (3. Windows WebClient does not like a dot at the end, but since the project id tag is appended this is not a problem.)
          "#{p.name.gsub(INVALID_CHARACTERS, ".").gsub(/\.{2,}/, ".")} [#{p.id}]" unless p.nil?
        else
          p.identifier unless p.nil?
        end
      end
    end
  end
end
