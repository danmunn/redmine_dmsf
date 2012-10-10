module Webdav
  class Base

    def mount
      raise NotImplementedError
    end

    def load_config(config)
      raise NotImplementedError
    end
  end
end