module RedmineDmsf
  module Patches
    module CustomFieldsHelper
      def self.included(base)
        base.class_eval do
          alias_method_chain :custom_fields_tabs, :customer_tab
        end
      end

      def custom_fields_tabs_with_customer_tab
        tabs = custom_fields_tabs_without_customer_tab
        tabs << {:name => 'DmsfFileRevisionCustomField', :partial => 'custom_fields/index', :label => :DMSF_custom_field}
      end
    end
  end
end
