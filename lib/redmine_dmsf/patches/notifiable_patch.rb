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
    # Notifiable
    module NotifiablePatch
      def self.prepended(base)
        class << base
          prepend ClassMethods
        end
      end

      # Class methods
      module ClassMethods
        ################################################################################################################
        # Overridden methods
        #
        def all
          notifications = super
          notifications << Redmine::Notifiable.new('dmsf_workflow_plural')
          notifications << Redmine::Notifiable.new('dmsf_legacy_notifications')
          notifications
        end
      end
    end
  end
end

# Apply the patch
unless defined?(EasyExtensions) || RedmineDmsf::Plugin.an_obsolete_plugin_present?
  Redmine::Notifiable.prepend RedmineDmsf::Patches::NotifiablePatch
end
