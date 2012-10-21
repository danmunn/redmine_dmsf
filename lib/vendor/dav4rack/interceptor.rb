require 'dav4rack/interceptor_resource'
module DAV4Rack
  class Interceptor
    def initialize(app, args={})
      @roots = args[:mappings].keys
      @args = args
      @app = app
      @intercept_methods = %w(OPTIONS PROPFIND PROPPATCH MKCOL COPY MOVE LOCK UNLOCK)
      @intercept_methods -= args[:ignore_methods] if args[:ignore_methods]
    end

    def call(env)
      path = env['PATH_INFO'].downcase
      method = env['REQUEST_METHOD'].upcase
      app = nil
      if(@roots.detect{|x| path =~ /^#{Regexp.escape(x.downcase)}\/?/}.nil? && @intercept_methods.include?(method))
        app = DAV4Rack::Handler.new(:resource_class => InterceptorResource, :mappings => @args[:mappings], :log_to => @args[:log_to])
      end
      app ? app.call(env) : @app.call(env)
    end
  end
end