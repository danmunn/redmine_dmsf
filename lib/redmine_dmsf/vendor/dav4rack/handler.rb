require 'dav4rack/logger'

module DAV4Rack
  
  class Handler
    include DAV4Rack::HTTPStatus    
    def initialize(options={})
      @options = options.dup
      unless(@options[:resource_class])
        require 'dav4rack/file_resource'
        @options[:resource_class] = FileResource
        @options[:root] ||= Dir.pwd
      end
      Logger.set(*@options[:log_to])
    end

    def call(env)
      begin
        start = Time.now
        request = Rack::Request.new(env)
        response = Rack::Response.new

        Logger.info "Processing WebDAV request: #{request.path} (for #{request.ip} at #{Time.now}) [#{request.request_method}]"
        
        controller = nil
        begin
          controller_class = @options[:controller_class] || Controller
          controller = controller_class.new(request, response, @options.dup)
          controller.authenticate
          res = controller.send(request.request_method.downcase)
          response.status = res.code if res.respond_to?(:code)
        rescue HTTPStatus::Unauthorized => status
          response.body = controller.resource.respond_to?(:authentication_error_msg) ? controller.resource.authentication_error_msg : 'Not Authorized'
          response['WWW-Authenticate'] = "Basic realm=\"#{controller.resource.respond_to?(:authentication_realm) ? controller.resource.authentication_realm : 'Locked content'}\""
          response.status = status.code
        rescue HTTPStatus::Status => status
          response.status = status.code
        end

        # Strings in Ruby 1.9 are no longer enumerable.  Rack still expects the response.body to be
        # enumerable, however.
        
        response['Content-Length'] = response.body.to_s.length unless response['Content-Length'] || !response.body.is_a?(String)
        response.body = [response.body] unless response.body.respond_to? :each
        response.status = response.status ? response.status.to_i : 200
        response.headers.keys.each{|k| response.headers[k] = response[k].to_s}
        
        # Apache wants the body dealt with, so just read it and junk it
        buf = true
        buf = request.body.read(8192) while buf

        Logger.debug "Response in string form. Outputting contents: \n#{response.body}" if response.body.is_a?(String)
        Logger.info "Completed in: #{((Time.now.to_f - start.to_f) * 1000).to_i} ms | #{response.status} [#{request.url}]"
        
        response.body.is_a?(Rack::File) ? response.body.call(env) : response.finish
      rescue Exception => e
        Logger.error "WebDAV Error: #{e}\n#{e.backtrace.join("\n")}"
        raise e
      end
    end
    
  end

end
