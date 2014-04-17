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

require 'dav4rack'

module RedmineDmsf
  module Webdav

    # ResourceProxy
    #
    # This is more of a factory approach of an object, class determines which class to
    # instantiate based on pathing information, it then populates @resource_c with this
    # object, and proxies calls made against class to it.
    class ResourceProxy < DAV4Rack::Resource

      def initialize(*args)
        super(*args)
        pinfo = path.split('/').drop(1)
        if (pinfo.length == 0) #If this is the base_path, we're at root
          @resource_c = IndexResource.new(*args)
        elsif (pinfo.length == 1) #This is first level, and as such, project path
          @resource_c = ProjectResource.new(*args)
        else #We made it all the way to DMSF Data
          @resource_c = DmsfResource.new(*args)
        end

        @resource_c.accessor= self unless @resource_c.nil?
      end

      
      def authenticate(username, password)
        # Bugfix: Current DAV4Rack (including production) authenticate against ALL requests
        # Microsoft Web Client will not attempt any authentication (it'd seem) until it's acknowledged
        # a completed OPTIONS request. Ideally this is a flaw with the controller, however as I'm not
        # going to fork it to ensure compliance, checking the request method in the authentication
        # seems the next best step, if the request method is OPTIONS return true, controller will simply
        # call the options method within, which accesses nothing, just returns headers about dav env.
        return true if ( @request.request_method.downcase == "options" && ( path == "/" || path.empty? ) )
        User.current = User.try_to_login(username, password) || nil
        return !User.current.anonymous? unless User.current.nil?
        false
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

      def creation_date
        @resource_c.creation_date
      end

      def last_modified
        @resource_c.last_modified
      end

      def last_modified=(time)
        @resource_c.last_modified=(time)
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

      def name
        @resource_c.name
      end

      def long_name
        @resource_c.long_name
      end

      def make_collection
        @resource_c.make_collection
      end

      def delete
        @resource_c.delete
      end

      def special_type
        @resource_c.special_type
      end

      def move(dest, overwrite)
        @resource_c.move(dest, overwrite)
      end

      def copy(dest, overwrite)
        @resource_c.copy(dest, overwrite)
      end

      def lock(*args)
        @resource_c.lock(*args)
      end

      def lock_check(*args)
        @resource_c.lock_check(*args)
      end

      def unlock(*args)
        @resource_c.unlock(*args)
      end

      def put(*args)
        @resource_c.put(*args)
      end

      def post(*args)
        @resource_c.post(*args)
      end

      def resource
        @resource_c
      end

      def get_property(*args)
        @resource_c.get_property(*args)
      end

      def property_names
        @resource_c.property_names
      end

    end
  end
end
