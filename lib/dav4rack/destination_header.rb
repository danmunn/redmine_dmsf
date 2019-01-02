require 'addressable/uri'

module DAV4Rack
  class DestinationHeader

    attr_reader :host, :path, :path_info

    # uri is expected to be a DAV4Rack::Uri instance
    def initialize(uri)
      @host = uri.host
      @path = uri.path
      unless @path_info = uri.path_info
        # nil path info means path is outside the realm of script_name
        raise ArgumentError, "invalid destination header value: #{uri.to_s}"
      end
    end

    # host must be the same, but path must differ
    def validate(host: nil, resource_path: nil)
      if host and self.host and self.host != host
        DAV4Rack::HTTPStatus::BadGateway
      elsif resource_path and self.path_info == resource_path
        DAV4Rack::HTTPStatus::Forbidden
      end
    end

  end
end
