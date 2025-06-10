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
    # ResourceProxy
    #
    # This is more of a factory approach of an object, class determines which class to
    # instantiate based on pathing information, it then populates @resource_c with this
    # object, and proxies calls made against class to it.
    class ResourceProxy < Dav4rack::Resource
      attr_reader :read_only

      delegate :propstats, to: :@resource_c
      delegate :set_property, to: :@resource_c
      delegate :options, to: :@resource_c
      delegate :lockdiscovery, to: :@resource_c
      delegate :lockdiscovery_xml, to: :@resource_c
      delegate :children, to: :@resource_c
      delegate :collection?, to: :@resource_c
      delegate :exist?, to: :@resource_c
      delegate :creation_date, to: :@resource_c
      delegate :last_modified, to: :@resource_c
      delegate :etag, to: :@resource_c
      delegate :content_type, to: :@resource_c
      delegate :content_length, to: :@resource_c
      delegate :get, to: :@resource_c
      delegate :special_type, to: :@resource_c
      delegate :name, to: :@resource_c
      delegate :long_name, to: :@resource_c
      delegate :get_property, to: :@resource_c
      delegate :remove_property, to: :@resource_c
      delegate :properties, to: :@resource_c

      def initialize(path, request, response, options)
        # Check the settings cache for each request
        Setting.check_cache
        # Return 404 - NotFound if WebDAV is not enabled
        raise NotFound unless RedmineDmsf.dmsf_webdav?

        super
        rc = get_resource_class(path)
        @resource_c = rc.new(path, request, response, options)
        @resource_c.accessor = self if @resource_c
        @read_only = RedmineDmsf.dmsf_webdav_strategy == 'WEBDAV_READ_ONLY'
      end

      def authenticate?(username, password)
        User.current = User.try_to_login(username, password)
        User.current && !User.current.anonymous?
      end

      def supports_locking?
        !@read_only
      end

      def put(request)
        raise BadGateway if @read_only

        @resource_c.put request
      end

      def delete
        raise BadGateway if @read_only

        @resource_c.delete
      end

      def copy(dest)
        raise BadGateway if @read_only

        @resource_c.copy dest
      end

      def move(dest)
        raise BadGateway if @read_only

        @resource_c.move dest
      end

      def make_collection
        raise BadGateway if @read_only

        @resource_c.make_collection
      end

      def lock(args)
        raise BadGateway if @read_only

        @resource_c.lock args
      end

      def lock_check(lock_scope = nil)
        @resource_c.lock_check lock_scope
      end

      def unlock(token)
        raise BadGateway if @read_only

        @resource_c.unlock token
      end

      def resource
        @resource_c
      end

      # Adds the given xml namespace to namespaces and returns the prefix
      def add_namespace(namespace, _prefix = '')
        return if namespace.blank?

        prefix = 'ns1'
        2.step do |i|
          break unless namespaces.value?(prefix)

          prefix = "ns#{i}"
        end
        namespaces[namespace] = prefix
        prefix
      end

      # returns the prefix for the given namespace, adding it if necessary
      def prefix_for(ns_href)
        namespaces[ns_href] || add_namespace(ns_href)
      end

      def authentication_realm
        RedmineDmsf::Webdav::AUTHENTICATION_REALM
      end

      private

      def get_resource_class(path)
        pinfo = path.split('/').drop(1)
        return IndexResource if pinfo.empty?

        return ProjectResource if pinfo.length == 1

        i = 1
        project = nil
        prj = nil
        while pinfo.length.positive?
          prj = BaseResource.get_project(Project, pinfo.first, project)
          break unless prj

          project = prj
          i += 1
          pinfo = path.split('/').drop(i)
        end
        prj ? ProjectResource : DmsfResource
      end
    end
  end
end
