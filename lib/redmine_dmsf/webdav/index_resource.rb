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
    class IndexResource < BaseResource
      
      def children
        unless @children
          @children = []
          load_projects Project.where(parent_id: nil)
        end
        @children
      end

      def collection?
        true
      end

      def creation_date
        Time.current
      end

      def last_modified
        Time.current
      end

      # Index resource ALWAYS exists
      def exist?
        true
      end

      def etag
        sprintf '%x-%x-%x', children.count, 4096, Time.current.to_i
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
        response['Content-Type'] = 'text/html'
        OK
      end

    end
  end
end
