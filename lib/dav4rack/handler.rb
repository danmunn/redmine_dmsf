# frozen_string_literal: true

module Dav4rack
  # Handler
  class Handler
    include Dav4rack::HttpStatus

    # Options:
    #
    # - resource_class: your Resource implementation
    # - controller_class: custom Controller implementation (optional).
    # - root_uri_path: Path the handler is mapped to. Any resources
    #   instantiated will only see the part of the path below this root.
    # - recursive_propfind_allowed (true) : set to false to disable
    #   potentially expensive Depth: Infinity propfinds
    # - all options are passed on to your resource implementation and are
    #   accessible there as @options.
    #
    def initialize(options = {})
      @options = options.dup
    end

    def call(env)
      start = Time.current
      r = setup_request env
      response = Rack::Response.new

      Rails.logger.info do
        "Processing WebDAV request: #{r.path} (for #{r.ip} at #{Time.current}) [#{r.request_method}]"
      end

      controller = setup_controller r, response
      controller.process
      postprocess_response response

      # Apache wants the body dealt with, so just read it and junk it
      buf = true
      buf = r.body.read(8_192) while buf

      Rails.logger.debug { "Response String:\n#{response.body}" } if response.body.is_a?(String)
      Rails.logger.info do
        duration = ((Time.current.to_f - start.to_f) * 1_000).to_i
        "Completed in: #{duration} ms | #{response.status} [#{r.url}]"
      end

      response.finish
    rescue StandardError => e
      Rails.logger.error "WebDAV Error: #{e.message}"
      raise e
    end

    private

    def postprocess_response(response)
      response['Content-Length'] ||= response.body.length.to_s if response.body.is_a?(String)
      response.body = [response.body] unless response.body.respond_to?(:each)
    end

    def setup_request(env)
      ::Dav4rack::Request.new env, @options
    end

    def setup_controller(request, response)
      controller_class.new request, response, @options
    end

    def controller_class
      @options[:controller_class] || ::Dav4rack::Controller
    end
  end
end
