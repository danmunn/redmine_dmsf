# encoding: utf-8
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

require_dependency 'application_helper'

module RedmineDmsf
  module Patches
    module ApplicationHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          
          alias_method_chain :calendar_for, :square_brackets
        end
      end

      module InstanceMethods

        # If the field_id contains square brackets, jQuery is unable to find the tag by it's ID and therefore the Date
        # picker is missing when a DMSF custom filed has got the date format.
        def calendar_for_with_square_brackets(field_id)
          field_id.gsub! '[', '\\\\\\['
          field_id.gsub! ']', '\\\\\\]'
          calendar_for_without_square_brackets field_id
        end
      
      end
    end
  end
end

# Apply the patch
Rails.configuration.to_prepare do
  unless ApplicationHelper.included_modules.include?(RedmineDmsf::Patches::ApplicationHelperPatch)
    ApplicationHelper.send(:include, RedmineDmsf::Patches::ApplicationHelperPatch)
  end
end