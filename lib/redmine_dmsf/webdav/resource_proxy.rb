require 'webrick/httputils'

module RedmineDmsf
  module Webdav
    class ResourceProxy < DAV4Rack::Resource

      include WEBrick::HTTPUtils

      def initialize(public_path, path, request, response, options)
        super(public_path, path, request, response, options)
        pinfo = path.split('/').drop(1)
        if (pinfo.length == 0) #If this is the base_path, we're at root
          @resource_c = IndexResource.new(public_path, path, request, response, options)
        elsif (pinfo.length == 1) #This is first level, and as such, project path
          @resource_c = ProjectResource.new(public_path, path, request, response, options)
        else #We made it all the way to DMSF Data
        end

        @resource_c.accessor= self unless @resource_c.nil?
      end

      def authenticate(username, password)
        User.current = User.try_to_login(username, password) || nil
        !User.current.nil?
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
    end
  end
end
