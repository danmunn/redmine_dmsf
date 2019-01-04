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

    # ResourceProxy
    #
    # This is more of a factory approach of an object, class determines which class to
    # instantiate based on pathing information, it then populates @resource_c with this
    # object, and proxies calls made against class to it.
    class ResourceProxy < DAV4Rack::Resource

      attr_reader :read_only

      def initialize(*args)
        # Return 404 - NotFound if WebDAV is not enabled
        raise NotFound unless Setting.plugin_redmine_dmsf['dmsf_webdav']
        super(*args)
        pinfo = path.split('/').drop(1)
        if pinfo.length == 0 # If this is the base_path, we're at root
          @resource_c = IndexResource.new(*args)
        elsif pinfo.length == 1 # This is the first level, and as such, project path
          @resource_c = ProjectResource.new(*args)
        else # We made it all the way to DMSF Data
          @resource_c = DmsfResource.new(*args)
        end
        @resource_c.accessor = self if @resource_c
        @read_only = Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_ONLY'
      end

      def authenticate(username, password)
        User.current = User.try_to_login(username, password)
        User.current && !User.current.anonymous?
      end

      def options(request, response)
        @resource_c.options request, response
      end

      def supports_locking?
        !@read_only
      end

      def lockdiscovery
        @resource_c.lockdiscovery
      end

      def lockdiscovery_xml
        @resource_c.lockdiscovery_xml
      end

      def children
        @resource_c.children
      end

      def collection?
        @resource_c.collection?
      end

      def exist?
        @resource_c.exist?
      end

      def really_exist?
        @resource_c.really_exist?
      end

      def creation_date
        @resource_c.creation_date
      end

      def last_modified
        @resource_c.last_modified
      end
      
      def etag
        @resource_c.etag
      end

      def content_type
        @resource_c.content_type
      end

      def content_length
        @resource_c.content_length
      end

      def get(request, response)
        @resource_c.get(request, response)
      end

      def put(request, response)
        raise BadGateway if @read_only
        @resource_c.put(request, response)
      end

      def delete
        raise BadGateway if @read_only
        @resource_c.delete
      end

      def copy(dest, overwrite, depth)
        raise BadGateway if @read_only
        @resource_c.copy(dest, overwrite, depth)
      end

      def move(dest, overwrite = false)
        raise BadGateway if @read_only
        @resource_c.move(dest, overwrite)
      end

      def make_collection
        raise BadGateway if @read_only
        @resource_c.make_collection
      end

      def special_type
        @resource_c.special_type
      end

      def lock(args)
        raise BadGateway if @read_only
        @resource_c.lock(args)
      end

      def lock_check(lock_scope = nil)
        @resource_c.lock_check(lock_scope)
      end

      def unlock(token)
        raise BadGateway if @read_only
        @resource_c.unlock(token)
      end

      def name
        @resource_c.name
      end

      def long_name
        @resource_c.long_name
      end

      def resource
        @resource_c
      end

      def get_property(element)
        @resource_c.get_property(element)
      end

      def properties
        @resource_c.properties
      end

      def propstats(response, stats)
        @resource_c.propstats(response, stats)
      end
    end
  end
end
