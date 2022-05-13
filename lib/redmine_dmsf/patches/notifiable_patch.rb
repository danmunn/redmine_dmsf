# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
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

    module NotifiablePatch

      def self.prepended(base)

        class << base
          prepend ClassMethods
        end

      end

      module ClassMethods

        ################################################################################################################
        # Overriden methods
        #
        def all
          notifications = super
          notifications << Redmine::Notifiable.new('dmsf_workflow_plural')
          notifications << Redmine::Notifiable.new('dmsf_legacy_notifications')
          notifications
        end

      end

    end

    # TODO: This is just a workaround to fix alias_method usage in redmine_resources plugin, which is in conflict with
    #   prepend and causes an infinite loop.
    module RedmineUpNotifiablePatch

      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          unloadable
          class << self
            alias_method :all_without_resources_dmsf, :all
            alias_method :all, :all_with_resources_dmsf
          end
        end
      end

      module ClassMethods

        def all_with_resources_dmsf
          notifications = all_without_resources_dmsf
          notifications << Redmine::Notifiable.new('dmsf_workflow_plural')
          notifications << Redmine::Notifiable.new('dmsf_legacy_notifications')
          notifications
        end

      end

    end

  end
end

# Apply the patch
if Redmine::Plugin.installed?(:easy_extensions)
  RedmineExtensions::PatchManager.register_patch_to_be_first 'Redmine::Notifiable',
    'RedmineDmsf::Patches::NotifiablePatch', prepend: true, first: true
else
  # redmine_resources depends on redmine_contact and redmine_contacts if alphabetically sorted before redmine_dmsf
  # in the plugin list.
  if Redmine::Plugin.installed?(:redmine_contacts)
    Redmine::Notifiable.send :include, RedmineDmsf::Patches::RedmineUpNotifiablePatch
  else
    Redmine::Notifiable.prepend RedmineDmsf::Patches::NotifiablePatch
  end
end