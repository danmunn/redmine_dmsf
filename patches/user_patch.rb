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
    # User
    module UserPatch
      ##################################################################################################################
      # New methods

      def self.prepended(base)
        base.class_eval do
          before_destroy :remove_dmsf_references, prepend: true
        end
      end

      private

      def remove_dmsf_references
        return if id.nil?

        substitute = User.anonymous
        DmsfFileRevisionAccess.where(user_id: id).update_all user_id: substitute.id
        DmsfFileRevision.where(user_id: id).update_all user_id: substitute.id
        DmsfFileRevision.where(dmsf_workflow_assigned_by_user_id: id).update_all(
          dmsf_workflow_assigned_by_user_id: substitute.id
        )
        DmsfFileRevision.where(dmsf_workflow_started_by_user_id: id).update_all(
          dmsf_workflow_started_by_user_id: substitute.id
        )
        DmsfFileRevision.where(user_id: id).update_all user_id: substitute.id
        DmsfFile.where(deleted_by_user_id: id).update_all deleted_by_user_id: substitute.id
        DmsfFolder.where(user_id: id).update_all user_id: substitute.id
        DmsfFolder.where(deleted_by_user_id: id).update_all deleted_by_user_id: substitute.id
        DmsfLink.where(user_id: id).update_all user_id: substitute.id
        DmsfLink.where(deleted_by_user_id: id).update_all deleted_by_user_id: substitute.id
        DmsfLock.where(user_id: id).delete_all
        DmsfWorkflowStepAction.where(author_id: id).update_all author_id: substitute.id
        DmsfWorkflowStepAssignment.where(user_id: id).update_all user_id: substitute.id
        DmsfWorkflowStep.where(user_id: id).update_all user_id: substitute.id
        DmsfWorkflow.where(author_id: id).update_all author_id: substitute.id
        DmsfFolderPermission.where(object_id: id, object_type: 'User').update_all object_id: substitute.id
      end
    end
  end
end

# Apply the patch
if defined?(EasyPatchManager)
  EasyPatchManager.register_model_patch 'User', 'RedmineDmsf::Patches::UserPatch'
else
  User.prepend RedmineDmsf::Patches::UserPatch
end
