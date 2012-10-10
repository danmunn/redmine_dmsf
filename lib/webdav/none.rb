module Webdav

  #This class should quite literally do nothing
  class None < Webdav::Base
    def mount
      #This is a placeholder to override Webdav::Base
    end

    def load_config(config)
      #This is a placeholder to override Webdav::Base
    end
  end
end