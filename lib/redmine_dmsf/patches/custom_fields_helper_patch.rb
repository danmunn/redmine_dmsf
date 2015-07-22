# encoding: utf-8
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš    <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn  <dan.munn@munnster.co.uk>
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
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

require_dependency 'custom_fields_helper'

module RedmineDmsf
  module Patches
    module CustomFieldsHelperPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          
          alias_method_chain :render_custom_fields_tabs, :render_custom_tab
          alias_method_chain :custom_field_type_options, :custom_tab_options          
        end
      end

      module ClassMethods
      end

      module InstanceMethods       

        def render_custom_fields_tabs_with_render_custom_tab(types)
          cf = {:name => 'DmsfFileRevisionCustomField', :partial => 'custom_fields/index', :label => :dmsf}          
          unless CustomFieldsHelper::CUSTOM_FIELDS_TABS.index { |f| f[:name] == cf[:name] }
            CustomFieldsHelper::CUSTOM_FIELDS_TABS << cf          
          end
          render_custom_fields_tabs_without_render_custom_tab(types)
        end

        def custom_field_type_options_with_custom_tab_options
          cf = {:name => 'DmsfFileRevisionCustomField', :partial => 'custom_fields/index', :label => :dmsf}          
          unless CustomFieldsHelper::CUSTOM_FIELDS_TABS.index { |f| f[:name] == cf[:name] }
            CustomFieldsHelper::CUSTOM_FIELDS_TABS << cf          
          end
          custom_field_type_options_without_custom_tab_options
        end
      
      end
    end
  end
end

# Apply the patch
Rails.configuration.to_prepare do
  unless CustomFieldsHelper.included_modules.include?(RedmineDmsf::Patches::CustomFieldsHelperPatch)
    CustomFieldsHelper.send(:include, RedmineDmsf::Patches::CustomFieldsHelperPatch)
  end
end