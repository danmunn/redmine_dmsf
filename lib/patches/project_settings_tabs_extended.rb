require_dependency 'projects_helper'

module Dmsf
  module Patches
    module ProjectSettingsTabsExtended

      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :project_settings_tabs, :dmsf
        end
      end

      module ClassMethods
      end

      module InstanceMethods
      
        def project_settings_tabs_with_dmsf
          tabs = project_settings_tabs_without_dmsf
          if @project.module_enabled? :dmsf
            tabs << {:name => 'dmsf', :controller => 'dmsf_workflows', :action => 'index', :partial => 'dmsf_workflows/main', :label => 'label_dmsf'}             
          end
          return tabs
        end

      end

    end
  end
end

#Apply patch
Rails.configuration.to_prepare do
  unless ProjectsHelper.included_modules.include?(Dmsf::Patches::ProjectSettingsTabsExtended)
    ProjectsHelper.send(:include, Dmsf::Patches::ProjectSettingsTabsExtended)
  end
end