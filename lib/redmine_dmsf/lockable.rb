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
  # Lockable
  module Lockable
    def locked?
      !lock.empty?
    end

    # lock:
    #   Returns an array with current lock objects that affect the current object
    #   optional: tree = true (show entire tree?)
    def lock(tree: true)
      ret = []
      unless locks.empty?
        locks.each do |lock|
          ret << lock unless lock.expired?
        end
      end
      if tree && dmsf_folder
        ret |= dmsf_folder.locks.empty? ? dmsf_folder.lock : dmsf_folder.locks
      end
      ret
    end

    def lock!(scope = :scope_exclusive, type = :type_write, expire = nil, owner = nil)
      # Raise a lock error if entity is locked, but its not at resource level
      existing = lock(tree: false)
      raise RedmineDmsf::Errors::DmsfLockError, l(:error_resource_or_parent_locked) if locked? && existing.empty?

      unless existing.empty?
        if (existing[0].lock_scope == :scope_shared) && (scope == :scope_shared)
          # RFC states if an item is exclusively locked and another lock is attempted we reject
          # if the item is shared locked however, we can always add another lock to it
          raise RedmineDmsf::Errors::DmsfLockError, l(:error_parent_locked) if dmsf_folder.locked?
        elsif scope == :scope_exclusive
          raise RedmineDmsf::Errors::DmsfLockError, l(:error_lock_exclusively)
        end
      end
      l = DmsfLock.new
      l.entity_id = id
      l.entity_type = is_a?(DmsfFile) ? 0 : 1
      l.lock_type = type
      l.lock_scope = scope
      l.user = User.current
      l.expires_at = expire
      l.dmsf_file_last_revision_id = last_revision.id if is_a?(DmsfFile)
      l.owner = owner
      l.save!
      reload # Reload the object being locked in order to contain just created lock when asked
      l
    end

    def unlockable?
      return false unless locked?

      existing = lock(tree: true)
      # If it's empty, it's a folder that's locked (not root)
      existing.empty? || dmsf_folder&.locked? ? false : true
    end

    # By using the path upwards, surely this would be quicker?
    def locked_for_user?(args = nil)
      return false unless locked?

      shared = nil
      dmsf_path.each do |entity|
        locks = entity.locks || entity.lock(false)
        next if locks.empty?

        locks.each do |lock|
          next if lock.expired? # In case we're in between updates

          owner = args[:owner] if args
          owner ||= User.current&.login if lock.owner
          if lock.lock_scope == :scope_exclusive
            return true if (lock.user&.id != User.current.id) || (lock.owner&.downcase != owner&.downcase)
          else
            shared = true if shared.nil?
            if (shared && (lock.user&.id == User.current.id) && (lock.owner&.downcase == owner&.downcase)) ||
               (args && (args[:scope] == 'shared'))
              shared = false
            end
          end
        end
        return true if shared
      end
      false
    end

    def unlock!(force_file_unlock_allowed: false, owner: nil)
      raise RedmineDmsf::Errors::DmsfLockError, l(:warning_file_not_locked) unless locked?

      existing = lock(tree: true)
      destroyed = false
      # If its empty its a folder that's locked (not root)
      if existing.empty? || (!dmsf_folder.nil? && dmsf_folder.locked?)
        raise RedmineDmsf::Errors::DmsfLockError, l(:error_unlock_parent_locked)
      end

      # If entity is locked to you, you aren't the lock originator (or named in a shared lock) so deny action
      # Unless of course you have the rights to force an unlock
      if locked_for_user? && !User.current.allowed_to?(:force_file_unlock, project) && !force_file_unlock_allowed
        raise RedmineDmsf::Errors::DmsfLockError, l(:error_only_user_that_locked_file_can_unlock_it)
      end

      # Now we need to determine lock type and do the needful
      if (existing.count == 1) && (existing[0].lock_scope == :exclusive)
        existing[0].destroy
        destroyed = true
      else
        existing.each do |lock|
          owner = User.current&.login if lock.owner && owner.nil?
          unless ((lock.user&.id == User.current.id) && (lock.owner&.downcase == owner&.downcase)) ||
                 User.current.admin?
            next
          end

          lock.destroy
          destroyed = true
          break
        end
        # At first it was going to be allowed for someone with force_file_unlock to delete all shared by default
        # Instead, they by default remove themselves from shared lock, and everyone from shared lock if they're not
        # on said lock
        if !destroyed && (User.current.allowed_to?(:force_file_unlock, project) || force_file_unlock_allowed)
          locks.delete_all
          destroyed = true
        end
      end

      if destroyed
        reload
        locks.reload
      end
      destroyed
    end
  end
end
