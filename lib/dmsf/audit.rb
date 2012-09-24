module Dmsf
  module Audit
    #Redirect any include to Dmsf::Audit::Base
    def self.included(base)
      base.send(:include, Dmsf::Audit::Base)
    end
  end
end