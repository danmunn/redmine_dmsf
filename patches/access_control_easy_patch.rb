# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

module RedmineDmsf
  module Patches
    # AccessControl patch
    # TODO: This is just a workaround to fix alias_method usage in Easy's plugins, which is in conflict with
    #   prepend and causes an infinite loop.
    module AccessControlEasyPatch
      ##################################################################################################################
      # Overridden methods
      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          class << self
            alias_method_chain :available_project_modules, :easy
          end
        end
      end

      # Class methods
      module ClassMethods
        def available_project_modules_with_easy
          # Removes the original Documents from project's modules (replaced with DMSF)
          modules = available_project_modules_without_easy
          modules.delete(:documents) if RedmineDmsf.remove_original_documents_module?
          modules
        end
      end
    end
  end
end

# Apply the patch
if defined?(EasyPatchManager)
  EasyPatchManager.register_other_patch 'Redmine::AccessControl', 'RedmineDmsf::Patches::AccessControlEasyPatch'
end
