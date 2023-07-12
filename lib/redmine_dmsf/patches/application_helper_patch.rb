# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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
    # ApplicationHelper patch
    module ApplicationHelperPatch
      ##################################################################################################################
      # Overridden methods

      def xapian_link_to_entity(entity, html_options = {})
        case entity.is_a?
        when DmsfFolder
          link_to h(entity.to_s), dmsf_folder_path(id: entity.project_id, folder_id: entity), class: 'icon icon-folder'
        when DmsfFile
          link_to h(entity.to_s), dmsf_file_path(id: entity), class: 'icon icon-file'
        else
          super
        end
      end
    end
  end
end

# Apply the patch
ApplicationHelper.prepend RedmineDmsf::Patches::ApplicationHelperPatch
