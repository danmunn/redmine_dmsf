# frozen_string_literal: true

require 'dav4rack/logger'

module DAV4Rack
  class Handler
    include DAV4Rack::HTTPStatus

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
    def initialize(options={})
      @options = options.dup

      Logger.set(*@options[:log_to])
    end

    def call(env)
      start = Time.now
      request = setup_request env
      response = Rack::Response.new

      Logger.info "Processing WebDAV request: #{request.path} (for #{request.ip} at #{Time.now}) [#{request.request_method}]"

      controller = setup_controller request, response
      controller.process
      postprocess_response response

      # Apache wants the body dealt with, so just read it and junk it
      buf = true
      buf = request.body.read(8192) while buf

      if Logger.debug? and response.body.is_a?(String)
        Logger.debug "Response String:\n#{response.body}"
      end
      Logger.info "Completed in: #{((Time.now.to_f - start.to_f) * 1000).to_i} ms | #{response.status} [#{request.url}]"

      response.finish

    rescue Exception => e
      Logger.error "WebDAV Error: #{e}"
      raise e
    end


    private


    def postprocess_response(response)
      if response.body.is_a?(String)
        response['Content-Length'] ||= response.body.length.to_s
      end
      response.body = [response.body] unless response.body.respond_to?(:each)
    end


    def setup_request(env)
      ::DAV4Rack::Request.new env, @options
    end


    def setup_controller(request, response)
      controller_class.new(request, response, @options)
    end

    def controller_class
      @options[:controller_class] || ::DAV4Rack::Controller
    end

  end

end
