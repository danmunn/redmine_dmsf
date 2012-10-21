module Webdav
  module Dmsf
    module Middleware
      class NoParse
        def initialize(app, options={})
          options ||= {}
          @app = app
          @url = options[:url]
          @url ||= Redmine::Application.routes.url_helpers.dmsf_webdav_path if
              Redmine::Application.routes.url_helpers.respond_to?(:dmsf_webdav_path)
        end

        def call(env)
          # Very simple, if the request is of type PUT and it has a content-type
          # AND it begins with @url (often the path to Dmsf Webdav), then we flag
          # the content type to text/plain to prevent Rails automatically attempting
          # to parse the content (such as xml etc...)
          if env['REQUEST_METHOD'] == "PUT" && env.has_key?('CONTENT_TYPE') then
            if (env['PATH_INFO'].starts_with? @url) then
              env['CONTENT_TYPE'] = 'text/plain'
            end
          end
          @app.call(env)
        end
      end
    end
  end
end