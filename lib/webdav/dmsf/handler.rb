require 'dav4rack' #We load the Dav4Rack framework here

module Webdav
  module Dmsf
    class Handler < ::DAV4Rack::Handler
      class Locked < ::Webdav::Dmsf::Handler
        def initialize(config)
          config ||= {}
          config.merge!({:controller_class => Webdav::Dmsf::Controller::Locked})
          super config
        end
      end
      def initialize(config)
        config ||= {}
        defaults = {
            :resource_class => Webdav::Dmsf::Resource::Proxy,
            :controller_class => Webdav::Dmsf::Controller,
            :root_uri_path => '/dmsf/webdav'
        }
        config = defaults.merge(config)
        super config
      end
    end
  end
end