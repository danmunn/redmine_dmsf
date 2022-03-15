require 'addressable/uri'

module Dav4rack
  class DestinationHeader

    attr_reader :host, :path, :path_info

    # uri is expected to be a Dav4rack::Uri instance
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
        Dav4rack::HttpStatus::BadGateway
      elsif resource_path and self.path_info == resource_path
        Dav4rack::HttpStatus::Forbidden
      end
    end

  end
end
