# Copyright (C) 2011   Vit Jons <vit.jonas@gmail.com>
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2013   Karel Picman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Patches
    module CustomFieldsHelper
      def self.included(base)
        base.class_eval do
          alias_method_chain :custom_fields_tabs, :customer_tab
        end
      end

      def custom_fields_tabs_with_customer_tab                    
        cf = {:name => 'DmsfFileRevisionCustomField', :partial => 'custom_fields/index', :label => :dmsf}
        unless CustomField::CUSTOM_FIELDS_NAMES.include?(cf[:name])
          CustomField::CUSTOM_FIELDS_TABS << cf
          CustomField::CUSTOM_FIELDS_NAMES << cf[:name]
        end        
        custom_fields_tabs_without_customer_tab        
      end
    end
  end
end

#Apply patch
Rails.configuration.to_prepare do
  unless CustomFieldsHelper.included_modules.include?(CustomFieldsHelper)
    CustomFieldsHelper.send(:include, RedmineDmsf::Patches::CustomFieldsHelper)
  end
end
