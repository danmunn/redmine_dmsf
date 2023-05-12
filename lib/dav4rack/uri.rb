# frozen_string_literal: true

require 'addressable/uri'
require 'English'

module Dav4rack
  # adds a bit of parsing logic around a header URI or path value
  class Uri
    attr_reader :host, :path, :path_info, :script_name

    def initialize(uri_or_path, script_name: nil)
      # More than one leading slash confuses Addressable::URI, resulting e.g.
      # with //remote.php/dav/files in a path of /dav/files with a host
      # remote.php.
      @uri_or_path = uri_or_path.to_s.strip.sub(%r{\A/+}, '/')
      @script_name = script_name
      parse
    end

    def to_s
      @uri_or_path
    end

    private

    def parse
      uri = Addressable::URI.parse @uri_or_path

      @host = uri.host
      @path = Addressable::URI.unencode uri.path

      if @script_name
        if @path =~ %r{\A(?<path>#{Regexp.escape @script_name}(?<path_info>/.*))\z}
          @path_info = $LAST_MATCH_INFO[:path_info]
        end
      else
        @path_info = @path
      end
    end
  end
end
