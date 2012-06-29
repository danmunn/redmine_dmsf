require 'time'
require 'rack/utils'
require 'rack/mime'

module DAV4Rack
  # DAV4Rack::File simply allows us to use Rack::File but with the
  # specific location we deem appropriate
  class File < Rack::File
    attr_accessor :path

    alias :to_path :path

    def initialize(path)
      @path = path
    end

    def _call(env)
      begin
        if F.file?(@path) && F.readable?(@path)
          serving
        else
          raise Errno::EPERM
        end
      rescue SystemCallError
        not_found
      end
    end

    def not_found
      body = "File not found: #{Rack::Utils.unescape(env["PATH_INFO"])}\n"
      [404, {"Content-Type" => "text/plain",
         "Content-Length" => body.size.to_s,
         "X-Cascade" => "pass"},
       [body]]
    end
  end
end
