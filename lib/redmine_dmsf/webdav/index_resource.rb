# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

module RedmineDmsf
  module Webdav
    # Index resource
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
        format '%<inode>x-%<size>x-%<modified>x', inode: children.count, size: 4096, modified: Time.current.to_i
      end

      def content_type
        'inode/directory'
      end

      def content_length
        4096
      end

      def get(_request, response)
        html_display
        response['Content-Length'] = response.body.bytesize.to_s
        response['Content-Type'] = 'text/html'
        OK
      end
    end
  end
end
