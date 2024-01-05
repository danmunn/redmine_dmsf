# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
#  Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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
    # Project helper
    module ProjectsHelperPatch
      ##################################################################################################################
      # Overridden methods

      def project_settings_tabs
        tabs = super
        dmsf_tabs =
          [
            {
              name: 'dmsf',
              action: { controller: 'dmsf_state', action: 'user_pref_save' },
              partial: 'dmsf_state/user_pref', label: :menu_dmsf
            },
            {
              name: 'dmsf_workflow',
              action: { controller: 'dmsf_workflows', action: 'index' },
              partial: 'dmsf_workflows/main', label: :label_dmsf_workflow_plural
            }
          ]
        tabs.concat(
          dmsf_tabs.select { |dmsf_tab| User.current.allowed_to?(dmsf_tab[:action], @project) }
        )
        tabs
      end
    end
  end
end

# Apply the patch
unless Redmine::Plugin.installed?('easy_extensions')
  ProjectsController.send :helper, RedmineDmsf::Patches::ProjectsHelperPatch
end
