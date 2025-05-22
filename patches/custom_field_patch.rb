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
    # CustomField patch
    module CustomFieldPatch
      def self.included(base)
        base.class_eval do
          safe_attributes :dmsf_not_inheritable
        end
      end
    end
  end
end

# Apply patch
if defined?(EasyPatchManager)
  EasyPatchManager.register_model_patch 'CustomField', 'RedmineDmsf::Patches::CustomFieldPatch'
else
  CustomField.include RedmineDmsf::Patches::CustomFieldPatch
end
