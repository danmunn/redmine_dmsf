# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require_dependency 'projects_helper'

module RedmineDmsf
  module Patches
    module ProjectTabsExtended

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
          if @project.module_enabled?("dmsf")
            tabs.push({:name => 'dmsf', :controller => :dmsf_state, :action => :user_pref_save, :partial => 'dmsf_state/user_pref', :label => :dmsf})
          end
          return tabs
        end

      end

    end
  end
end

#Apply patch
Rails.configuration.to_prepare do
  unless ProjectsHelper.included_modules.include?(RedmineDmsf::Patches::ProjectTabsExtended)
    ProjectsHelper.send(:include, RedmineDmsf::Patches::ProjectTabsExtended)
  end
end