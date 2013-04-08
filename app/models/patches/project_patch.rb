require_dependency 'project'

module Dmsf
  module Patches
    module ProjectPatch

      def self.included(base) # :nodoc:        
        base.class_eval do                    
          has_many :dmsf_workflows, :dependent => :destroy
        end
      end
      
    end
  end
end

#Apply patch
Rails.configuration.to_prepare do  
  Project.send(:include, Dmsf::Patches::ProjectPatch)
end
