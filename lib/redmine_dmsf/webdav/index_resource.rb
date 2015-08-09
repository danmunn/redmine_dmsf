# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
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
    class IndexResource < BaseResource

      def initialize(public_path, path, request, response, options)
        super(public_path, path, request, response, options)
      end

      def children
        if @projects.blank?
          @projects = []
          if User.current.admin?            
            @projects = Project.visible.order('lft').to_a
          elsif User.current.logged? # If user is not admin, we should only show memberships relevant
            User.current.memberships.each{ |m| @projects << m.project if m.roles.detect{ |r| r.allowed_to?(:view_dmsf_folders) } }
          end
        end 
        @projects.delete_if { |node| !node.module_enabled?('dmsf') } if @projects
        return [] if @projects.blank?
        @projects.map do |p|
          child p.identifier
        end
      end

      def collection?
        true
      end

      def creation_date
        Time.now
      end

      def last_modified
        Time.now
      end

      def last_modified=
        MethodNotAllowed
      end

      # Index resource ALWAYS exists
      def exist?
        true
      end

      def etag
        sprintf('%x-%x-%x', children.count, 4096, Time.now.to_i)
      end

      def content_type
        'inode/directory'
      end

      def content_length
        4096
      end

      def get(request, response)
        html_display
        response['Content-Length'] = response.body.bytesize.to_s
        OK
      end

      # Bugfix: Ensure that this level never indicates a parent
      def parent
        nil
      end

    end
  end
end
