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
    # Notifiable
    module NotifiablePatch
      def self.prepended(base)
        base.singleton_class.prepend(ClassMethods)
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
unless defined?(EasyPatchManager) || RedmineDmsf::Plugin.an_obsolete_plugin_present?
  Redmine::Notifiable.prepend RedmineDmsf::Patches::NotifiablePatch
end
