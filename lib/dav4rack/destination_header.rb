require 'addressable/uri'

module DAV4Rack
  class DestinationHeader

    attr_reader :host, :path, :path_info

    def initialize(value, script_name: nil)
      @script_name = script_name.to_s
      @value = value.to_s.strip
      parse
    end

    def parse
      uri = Addressable::URI.parse @value

      @host = uri.host
      @path = Addressable::URI.unencode uri.path

      if @script_name
        if @path =~ /\A(?<path>#{Regexp.escape @script_name}(?<path_info>\/.*))\z/
          @path_info = $~[:path_info]
        else
          raise ArgumentError, 'invalid destination header value'
        end
      end
    end

    # host must be the same, but path must differ
    def validate(host: nil, resource_path: nil)
      if host and self.host and self.host != host
        DAV4Rack::HTTPStatus::BadGateway
      elsif self.path == resource_path
        DAV4Rack::HTTPStatus::Forbidden
      end
    end

  end
end
