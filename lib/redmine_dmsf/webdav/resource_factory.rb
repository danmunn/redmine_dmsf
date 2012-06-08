module RedmineDmsf
  module Webdav
    class ResourceFactory < DAV4Rack::Resource

      def initialize(public_path, path, request, response, options)
        super(public_path, path, request, response, options)
        if (path == "")
        end
      end

      def authenticate(username, password)
        User.try_to_login(username, password) ? true : false
      end

    end
  end
end
