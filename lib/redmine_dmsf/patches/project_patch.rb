require_dependency 'project'
module RedmineDmsf
  module Patches
    module ProjectPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      module InstanceMethods
        def all_dmsf_custom_fields
          @all_dmsf_custom_fields ||= (DmsfFileRevisionCustomField.for_all).uniq.sort # + dmsf_file_revision_custom_fields).uniq.sort
        end
      end
    end
  end
end
