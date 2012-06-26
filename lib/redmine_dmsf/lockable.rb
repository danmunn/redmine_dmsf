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
        ret = ret | folder.lock unless folder.nil?
      end
      return ret
    end

    def lock! scope = :exclusive, type = :write
      l = DmsfLock.lock_state(self, scope, type)
      self.reload
      return l
    end

    #
    # By using the path upwards, surely this would be quicker?
    def locked_for_user?(tree = true)
      return false unless locked?
      b_shared = nil
      heirarchy = self.dmsf_path
      heirarchy.each {|folder|
        locks = folder.lock(false)
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

#    #Any better suggestions on this? - This is quite cumbersome
#    def locked_for_user_old?
#      return false unless locked?
#      b_shared = nil
#
#      unless locks.empty?
#        locks.each {|lock|
#          continue if lock.expired? #Incase we're inbetween updates
#          if (lock.lock_scope == :scope_exclusive && b_shared.nil?)
#            return true if lock.user.id != User.current.id
#          else
#            b_shared = true if b_shared.nil?
#            b_shared = false if lock.user.id == User.current.id
#          end
#        }
#        return true if b_shared
#      end
#      return folder.locked_for_user? unless folder.nil?
#      false
#    end

    def unlock!
      l = DmsfLock.lock_state(self, false)
      self.reload
      return l
    end

  end
end
