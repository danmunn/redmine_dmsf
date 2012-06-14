module RedmineDmsf
  class NoParse
    def initialize(app, options={})
      @app = app
      @urls = options[:urls]
    end

    def call(env)
      if env['REQUEST_METHOD'] == "PUT" && env.has_key?('CONTENT_TYPE') then
        if (@urls.dup.delete_if {|x| !env['PATH_INFO'].starts_with? x}.length > 0) then
          logger "RedmineDmsf::NoParse prevented mime parsing for PUT #{env['PATH_INFO']}"
          env['CONTENT_TYPE'] = 'text/plain'
        end
      end
      @app.call(env)
    end

    private

      def logger(env)
        env['action_dispatch.logger'] || Logger.new($stdout)
      end

  end
end
