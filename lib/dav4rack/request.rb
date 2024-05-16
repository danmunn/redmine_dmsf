# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/uri"
require 'addressable/uri'

module Dav4rack
  # Request
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
      self.path_info = expand_path path_info
    end

    def authorization?
      !!authorization
    end

    def authorization
      get_header('HTTP_AUTHORIZATION') ||
        get_header('X-HTTP_AUTHORIZATION') ||
        get_header('X_HTTP_AUTHORIZATION') ||
        get_header('REDIRECT_X_HTTP_AUTHORIZATION')
    end

    # path relative to root uri
    def unescaped_path_info
      @unescaped_path_info ||= self.class.unescape_path path_info
    end

    # the full path (script_name aka rack mount point + path_info)
    def unescaped_path
      @unescaped_path ||= self.class.unescape_path path
    end

    def self.unescape_path(path)
      p = path.dup
      p.force_encoding 'UTF-8'
      Addressable::URI.unencode p
    end

    # Namespace being used within XML document
    def ns(wanted_uri = XmlElements::DAV_NAMESPACE)
      if document && (root = document.root) && (ns_defs = root.namespace_definitions) && !ns_defs.empty?
        result = ns_defs.detect { |nd| nd.href == wanted_uri } || ns_defs.first
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
      @depth ||= if (d = get_header('HTTP_DEPTH')) && %w[0 1].include?(d)
                   d.to_i
                 elsif infinity_depth_allowed?
                   'infinity'
                 else
                   1
                 end
    end

    # Destination header
    def destination
      unless @destination
        h = get_header('HTTP_DESTINATION')
        @destination = DestinationHeader.new Dav4rack::Uri.new(h, script_name: script_name) if h
      end
      @destination
    end

    # Overwrite is allowed
    def overwrite?
      get_header('HTTP_OVERWRITE').to_s.casecmp('F').zero?
    end

    # content_length as a Fixnum (nil if the header is unset / empty)
    def content_length
      length = super || get_header('HTTP_X_EXPECTED_ENTITY_LENGTH')
      length&.to_i
    end

    # parsed XML request body if any (Nokogiri XML doc)
    def document
      @request_document ||= parse_request_body if content_length&.positive?
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
      path << '/' if collection && path[-1] != '/'
      "#{script_name}#{expand_path path}"
    end

    # returns the given path, but with the leading script_name removed. Will
    # return nil if the path does not begin with the script_name
    def path_info_for(full_path, script_name: self.script_name)
      uri = Dav4rack::Uri.new full_path, script_name: script_name
      uri.path_info
    end

    # expands '/foo/../bar' to '/bar', peserving trailing slash and normalizing
    # consecutive slashes. adds a leading slash if missing
    def expand_path(path)
      path = path.squeeze '/'
      path.prepend '/' unless path[0] == '/'
      collection = path.end_with?('/')
      path = ::File.expand_path path
      path << '/' if collection && !path.end_with?('/')
      # remove a drive letter in Windows
      path.gsub(%r{^([^/]*)/}, '/')
    end

    REDIRECTABLE_CLIENTS = [
      /cyberduck/i,
      /konqueror/i
    ].freeze

    # Does client allow GET redirection
    # TODO: Get a comprehensive list in here.
    # TODO: Allow this to be dynamic so users can add regexes to match if they know of a client
    # that can be supported that is not listed.
    def client_allows_redirect?
      ua = user_agent
      REDIRECTABLE_CLIENTS.any? { |re| ua =~ re }
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

    def parse_request_body
      Nokogiri.XML(body.read, &:strict) if body
    rescue StandardError => e
      Rails.logger.error e.message
      raise Dav4rack::HttpStatus::BadRequest
    end
  end
end
