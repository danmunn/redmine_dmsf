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
    # Role
    module RolePatch
      ##################################################################################################################
      # New methods

      def self.included(base)
        base.class_eval do
          before_destroy :remove_dmsf_references, prepend: true
        end
      end

      def remove_dmsf_references
        return unless id

        substitute = Role.anonymous
        DmsfFolderPermission.where(object_id: id, object_type: 'Role').update_all object_id: substitute.id
      end
    end
  end
end

# Apply the patch
if defined?(EasyPatchManager)
  EasyPatchManager.register_model_patch 'Role', 'RedmineDmsf::Patches::RolePatch', prepend: true
else
  Role.prepend RedmineDmsf::Patches::RolePatch
end
