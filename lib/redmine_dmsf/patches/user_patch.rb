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
    module UserPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          before_destroy :remove_dmsf_references
        end
      end

      module InstanceMethods

        def remove_dmsf_references
          return if self.id.nil?
          substitute = User.anonymous
          DmsfFileRevisionAccess.where(:user_id => id).update_all(:user_id => substitute.id)
          DmsfFileRevision.where(:user_id => id).update_all(:user_id => substitute.id)
          DmsfFile.where(:deleted_by_user_id => id).update_all(:deleted_by_user_id => substitute.id)
          DmsfFolder.where(:user_id => id).update_all(:user_id => substitute.id)
          DmsfFolder.where(:deleted_by_user_id => id).update_all(:deleted_by_user_id => substitute.id)
          DmsfLink.where(:user_id => id).update_all(:user_id => substitute.id)
          DmsfLink.where(:deleted_by_user_id => id).update_all(:deleted_by_user_id => substitute.id)
          DmsfLock.delete_all(:user_id => id)
          DmsfWorkflowStepAction.where(:author_id => id).update_all(:author_id => substitute.id)
          DmsfWorkflowStepAssignment.where(:user_id => id).update_all(:user_id => substitute.id)
          DmsfWorkflowStep.where(:user_id => id).update_all(:user_id => substitute.id)
          DmsfWorkflow.where(:author_id => id).update_all(:author_id => substitute.id)
        end

      end

    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless User.included_modules.include?(RedmineDmsf::Patches::UserPatch)
    User.send(:include, RedmineDmsf::Patches::UserPatch)
  end
end
