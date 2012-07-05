# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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
        if @Projects.nil? || @Projects.empty?
          @Projects = []
          if User.current.admin?
            @Projects = Project.visible.find(:all, :order => 'lft')
          elsif User.current.logged? #If user is not admin, we should only show memberships relevent
            User.current.memberships.each {|m| @Projects << m.project if m.roles.detect {|r| r.allowed_to?(:view_dmsf_folders)}}
          end
        end 
        @Projects.delete_if { |node|  node.module_enabled?('dmsf').nil? } unless @Projects.nil?
        return [] if @Projects.nil? || @Projects.empty?
        @Projects.map do |p|
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

      #Index resource ALWAYS exists
      def exist?
        true
      end

      def etag
        sprintf('%x-%x-%x', children.count, 4096, Time.now.to_i)
      end

      def content_type
        "inode/directory"
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
