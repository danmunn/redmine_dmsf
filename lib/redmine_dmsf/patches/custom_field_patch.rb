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
if Redmine::Plugin.installed?('easy_extensions')
  EasyPatchManager.register_model_patch 'CustomField', 'RedmineDmsf::Patches::CustomFieldPatch'
else
  CustomField.include RedmineDmsf::Patches::CustomFieldPatch
end
