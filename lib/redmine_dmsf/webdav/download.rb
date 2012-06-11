require 'time'
require 'rack/utils'
require 'rack/mime'

module RedmineDmsf
  module Webdav
    class Download < Rack::File
      def initialize(root, cache_control = nil)
        @path = root
        @cache_control = cache_control
      end

      def _call(env)
        unless ALLOWED_VERBS.include? env["REQUEST_METHOD"]
          return fail(405, "Method Not Allowed")
        end

        available = begin
          F.file?(@path) && F.readable?(@path)
        rescue SystemCallError
          false
        end

        if available
          serving(env)
        else
          raise NotFound
        end
      end
    end
  end
end
