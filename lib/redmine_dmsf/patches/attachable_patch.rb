# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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
    module AttachablePatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :has_attachments?, :has_attachments_dms
        end
      end

      module InstanceMethods

        def has_attachments_with_has_attachments_dms?
          has_attachments_without_has_attachments_dms? || (defined?(self.dmsf_files) && self.dmsf_files.any?)
        end

      end
    end
  end
end

 # Apply the patch
 Rails.configuration.to_prepare do
   unless Redmine::Acts::Attachable::InstanceMethods.included_modules.include?(RedmineDmsf::Patches::AttachablePatch)
     Redmine::Acts::Attachable::InstanceMethods.send(:include, RedmineDmsf::Patches::AttachablePatch)
   end
 end
