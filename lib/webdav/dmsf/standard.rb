module Webdav
  module Dmsf
    class Standard < Webdav::Base
      class Locked < Webdav::Dmsf::Standard
        def rails_mount
          @mountable = Webdav::Dmsf::Handler::Locked
          super
        end
      end

      def rails_mount
        mount_point = @config[:mount_point]
        mountable = @mountable || Webdav::Dmsf::Handler
        #Question, should we use Redmine or Rails?
        RedmineApp::Application.routes.append do
          mount mountable.new(
                    :root_uri_path => mount_point
                ) => mount_point, :as => 'dmsf_webdav'
        end

        # Our mountable for Webdav::Dmsf require the NoParse middleware -
        #so we'll load that now too!
        Rails.configuration.middleware.insert_before(ActionDispatch::ParamsParser,
                                                     Webdav::Dmsf::Middleware::NoParse)
      end

      def load_config(config)
        config ||= {}
        default = {
            :mount_point => '/dmsf/webdav'
        }
        @config = default.merge(config)
      end
    end
  end
end