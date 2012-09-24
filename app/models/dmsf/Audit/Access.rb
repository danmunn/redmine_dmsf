module Dmsf
  module Audit
    class Access < Base
      def self.ACCESS_TYPE_DOWNLOAD
        1
      end
      def self.ACCESS_TYPE_EMAIL
        2
      end
    end
  end
end