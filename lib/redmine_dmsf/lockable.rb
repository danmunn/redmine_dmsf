module RedmineDmsf
  module Lockable

    def locked?
      !lock.empty?
    end

    # lock:
    #   Returns an array with current lock objects that affect the current object
    #   optional: tree = true (show entire tree?)
    def lock(tree = true)
      ret = []
      unless locks.empty?
        locks.each {|lock|
          ret << lock unless lock.expired?
        }
      end
      if tree
        ret = ret | (folder.locks.empty? ? folder.lock : folder.locks) unless folder.nil?
      end
      return ret
    end

    def lock! scope = :scope_exclusive, type = :type_write, expire = nil
      # Raise a lock error if entity is locked, but its not at resource level
      existing = locks(false)
      raise DmsfLockError.new("Unable to complete lock - resource (or parent) is locked") if self.locked? && existing.empty?
      unless existing.empty?
        if existing[0].lock_scope == :scope_shared && scope == :scope_shared
          # RFC states if an item is exclusively locked and another lock is attempted we reject
          # if the item is shared locked however, we can always add another lock to it
          if self.folder.locked?
            raise DmsfLockError.new("Unable to complete lock - resource parent is locked")
          else
            existing.each {|l|
              raise DmsfLockError.new("Unable to complete lock - resource is locked") if l.user.id == User.current.id
            }
          end
        else
          raise DmsfLockError.new("unable to lock exclusively an already-locked resource") if scope == :scope_exclusive
        end
      end
      l = DmsfLock.new
      l.entity_id = self.id
      l.entity_type = self.is_a?(DmsfFile) ? 0 : 1
      l.lock_type = type
      l.lock_scope = scope
      l.user = User.current
      l.expires_at = expire
      l.save!
      reload
      locks.reload
      return l
    end

    def unlockable?
      return false unless self.locked?
      existing = self.lock(true)
      return false if existing.empty? || (!self.folder.nil? && self.folder.locked?) #If its empty its a folder thats locked (not root)
      true
    end

    #
    # By using the path upwards, surely this would be quicker?
    def locked_for_user?(tree = true)
      return false unless locked?
      b_shared = nil
      heirarchy = self.dmsf_path
      heirarchy.each {|folder|
        locks = folder.locks || folder.lock(false)
        next if locks.empty?
        locks.each {|lock|
          next if lock.expired? #Incase we're inbetween updates
          if (lock.lock_scope == :scope_exclusive && b_shared.nil?)
            return true if lock.user.id != User.current.id
          else
            b_shared = true if b_shared.nil?
            b_shared = false if lock.user.id == User.current.id
          end
        }
        return true if b_shared
      }
      false
    end

    def unlock!
      raise DmsfLockError.new("Unable to complete unlock - requested resource is not reported locked") unless self.locked?
      existing = self.lock(true)
      if existing.empty? || (!self.folder.nil? && self.folder.locked?) #If its empty its a folder thats locked (not root)
        raise DmsfLockError.new("Unlock failed - resource parent is locked")
      else
        # If entity is locked to you, you arent the lock originator (or named in a shared lock) so deny action
        # Unless of course you have the rights to force an unlock
        raise DmsfLockError.new("Unlock failed - resource is locked by another user") if (
              self.locked_for_user?(false) &&
              !User.current.allowed_to?(:force_file_unlock, self.project))

        #Now we need to determine lock type and do the needful
        if (existing.count == 1 && existing[0].lock_scope == :exclusive)
          existing[0].destroy
        else
          b_destroyed = false
          existing.each {|lock|
            if (lock.user.id == User.current.id)
              lock.destroy
              b_destroyed = true
              break
            end
          }
          # At first it was going to be allowed for someone with force_file_unlock to delete all shared by default
          # Instead, they by default remove themselves from sahred lock, and everyone from shared lock if they're not
          # on said lock
          if (!b_destroyed && User.current.allowed_to?(:force_file_unlock, self.project))
            locks.delete_all
          end
        end
      end

      reload
      locks.reload
    end
    true
  end
end
