module RedmineDmsf
  module Webdav
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
        User.current = User.try_to_login(username, password) || nil
        return !User.current.anonymous? unless User.current.nil?
        return false
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
        @resource_c.check_lock(*args)
      end

      def unlock(*args)
        @resource_c.unlock(*args)
      end

      def resource
        @resource_c
      end
    end
  end
end
