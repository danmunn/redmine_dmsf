module Webdav
  class Base

    def rails_mount
      raise NotImplementedError
    end

    def load_config(config)
      @config = config || {}
    end
  end
end