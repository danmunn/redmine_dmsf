# frozen_string_literal: true

require 'uri'
require 'addressable/uri'
require 'dav4rack/logger'

module DAV4Rack
  class Request < Rack::Request

    # Root URI path for the resource
    attr_reader :root_uri_path

    # options:
    #
    # recursive_propfind_allowed (true) : set to false to disable
    # potentially expensive recursive propfinds
    #
    def initialize(env, options = {})
      super env
      @options = { recursive_propfind_allowed: true }.merge options
      sanitize_path_info
    end


    def authorization?
      !!env['HTTP_AUTHORIZATION']
    end

    # path relative to root uri
    def unescaped_path_info
      @unescaped_path_info ||= self.class.unescape_path path_info
    end

    # the full path (script_name aka rack mount point + path_info)
    def unescaped_path
      @unescaped_path ||= self.class.unescape_path path
    end

    def self.unescape_path(p)
      p = p.dup
      p.force_encoding 'UTF-8'
      Addressable::URI.unencode p
    end


    # Namespace being used within XML document
    def ns(wanted_uri = XmlElements::DAV_NAMESPACE)
      if document and
        root = document.root and
        ns_defs = root.namespace_definitions and
        ns_defs.size > 0

        result = ns_defs.detect{ |nd| nd.href == wanted_uri } || ns_defs.first
        result = result.prefix.nil? ? 'xmlns' : result.prefix.to_s
        result += ':' unless result.empty?
        result
      else
        ''
      end
    end



    # Lock token if provided by client
    def lock_token
      get_header 'HTTP_LOCK_TOKEN'
    end


    # Requested depth
    def depth
      @http_depth ||= begin
        if d = get_header('HTTP_DEPTH') and (d == '0' or d == '1')
          d.to_i
        elsif infinity_depth_allowed?
          :infinity
        else
          1
        end
      end
    end


    # Destination header
    def destination
      @destination ||= if h = get_header('HTTP_DESTINATION')
        DestinationHeader.new h, script_name: script_name
      end
    end


    # Overwrite is allowed
    def overwrite?
      get_header('HTTP_OVERWRITE').to_s.upcase != 'F'
    end

    # content_length as a Fixnum (nil if the header is unset / empty)
    def content_length
      if length = (super || get_header('HTTP_X_EXPECTED_ENTITY_LENGTH'))
        length.to_i
      end
    end

    # parsed XML request body if any (Nokogiri XML doc)
    def document
      @request_document ||= parse_request_body if content_length && content_length > 0
    end

    # builds a URL for path using this requests scheme, host, port and
    # script_name
    # path must be valid UTF-8 and will be url encoded by this method
    def url_for(rel_path, collection: false)
      path = path_for rel_path, collection: collection
      "#{scheme}://#{host}:#{port}#{path}"
    end

    # returns an url encoded, absolute path for the given relative path
    def path_for(rel_path, collection: false)
      path = Addressable::URI.encode_component rel_path, Addressable::URI::CharacterClasses::PATH
      if collection and path[-1] != ?/
        path << '/'
      end
      "#{script_name}#{expand_path path}"
    end

    # expands '/foo/../bar' to '/bar'
    def expand_path(path)
      path.squeeze! '/'
      path = Addressable::URI.normalize_component path, Addressable::URI::CharacterClasses::PATH
      URI("http://example.com/").merge(path).path
    end


    REDIRECTABLE_CLIENTS = [
      /cyberduck/i,
      /konqueror/i
    ]

    # Does client allow GET redirection
    # TODO: Get a comprehensive list in here.
    # TODO: Allow this to be dynamic so users can add regexes to match if they know of a client
    # that can be supported that is not listed.
    def client_allows_redirect?
      ua = self.user_agent
      REDIRECTABLE_CLIENTS.any? { |re| ua =~ re }
    end


    MS_CLIENTS = [
      /microsoft-webdav/i,
      /microsoft office/i
    ]

    # Basic user agent testing for MS authored client
    def is_ms_client?
      ua = self.user_agent
      MS_CLIENTS.any? { |re| ua =~ re }
    end

    def get_header(name)
      @env[name]
    end

    private

    # true if Depth: Infinity is allowed for this request.
    #
    # http://www.webdav.org/specs/rfc4918.html#METHOD_PROPFIND
    # Servers ... should support "infinity" requests. In practice,
    # support for infinite-depth requests may be disabled, due to the
    # performance and security concerns associated with this behavior
    def infinity_depth_allowed?
      request_method != 'PROPFIND' or @options[:recursive_propfind_allowed]
    end

    def sanitize_path_info
      self.path_info.force_encoding 'UTF-8'
      self.path_info = expand_path path_info
    end

    def parse_request_body
      return Nokogiri.XML(body.read){ |config|
        config.strict
      } if body
    rescue
      DAV4Rack::Logger.error $!.message
      raise ::DAV4Rack::HTTPStatus::BadRequest
    end

  end
end
