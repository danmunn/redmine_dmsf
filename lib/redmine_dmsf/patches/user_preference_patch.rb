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
    # User preference
    module UserPreferencePatch
      ##################################################################################################################
      # New methods

      UserPreference.safe_attributes 'dmsf_attachments_upload_choice'

      def dmsf_attachments_upload_choice
        self[:dmsf_attachments_upload_choice] || 'DMSF'
      end

      def dmsf_attachments_upload_choice=(value)
        self[:dmsf_attachments_upload_choice] = value
      end

      UserPreference.safe_attributes 'default_dmsf_query'

      def default_dmsf_query
        self[:default_dmsf_query] || nil
      end

      def default_dmsf_query=(value)
        self[:default_dmsf_query] = value
      end

      UserPreference.safe_attributes 'receive_download_notification'

      def receive_download_notification
        self[:receive_download_notification] || '0'
      end

      def receive_download_notification=(value)
        self[:receive_download_notification] = value
      end
    end
  end
end

# Apply the patch
if Redmine::Plugin.installed?('easy_extensions')
  EasyPatchManager.register_model_patch 'UserPreference', 'RedmineDmsf::Patches::UserPreferencePatch'
else
  UserPreference.prepend RedmineDmsf::Patches::UserPreferencePatch
end
