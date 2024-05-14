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
#
module RedmineDmsf
  module Patches
    # Queries controller
    module QueriesControllerPatch
      ##################################################################################################################
      # New methods

      private

      def redirect_to_dmsf_query(options)
        if @project
          redirect_to dmsf_folder_path(@project, options)
        else
          redirect_to home_path(options)
        end
      end
    end
  end
end

# Apply the patch
if Redmine::Plugin.installed?('easy_extensions')
  EasyPatchManager.register_controller_patch 'QueriesController', 'RedmineDmsf::Patches::QueriesControllerPatch',
                                             prepend: true
else
  QueriesController.prepend RedmineDmsf::Patches::QueriesControllerPatch
end
