# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Patches
    # AccessControll patch
    module AccessControlPatch
      ##################################################################################################################
      # Overridden methods
      def self.prepended(base)
        class << base
          prepend ClassMethods
        end
      end

      # Class methods
      module ClassMethods
        def available_project_modules
          # Removes the original Documents from project's modules (replaced with DMSF)
          if Setting.plugin_redmine_dmsf['remove_original_documents_module']
            super.reject { |m| m == :documents }
          else
            super
          end
        end
      end
    end
  end
end

# Apply the patch
if Redmine::Plugin.installed?('easy_extensions')
  EasyPatchManager.register_patch_to_be_first 'Redmine::Acts::Attachable::InstanceMethods',
                                              'RedmineDmsf::Patches::AccessControlPatch', prepend: true, first: true
else
  Redmine::AccessControl.prepend RedmineDmsf::Patches::AccessControlPatch
end
