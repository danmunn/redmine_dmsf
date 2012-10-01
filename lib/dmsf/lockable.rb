module Dmsf
  module Lockable

    class ResourceLocked < IOError; end
    class ResourceParentLocked < IOError; end
    class ResourceNotLocked < RuntimeError; end
    class LockNotOwnedByPrincipal < SecurityError; end

    def self.included(base)
      #Extend Static (Class) Methods
      base.extend(ClassMethods)

      #Send Instance methods
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :locks, :class_name => Dmsf::Lock,
                 :foreign_key => "entity_id",
                 :dependent => :destroy
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      # Based on objects hierarchy, establishes its tree including
      # any and all locks.
      #
      # * *Args*    :
      #   - None
      # * *Returns* :
      #   - +Active::Relation+ -> Entity + Tree + Locks
      #
      def tree_with_locks
        return @tree_with_locks unless @tree_with_locks.nil?
        @tree_with_locks = self.self_and_ancestors.includes(:locks)
      end

      # Overload ActiveRecord::Base implementation of reload
      # with ours providing a reset and then calling on the
      # overloaded method to ensure functionality is preserved.
      #
      # We are resetting internal caches to ensure information is
      # considered expired.
      #
      # * *Args*    :
      #   - any
      # * *Returns* :
      #   - None
      #
      def reload(*args)
        @tree_with_locks = nil
        @effective_locks = nil
        super *args
      end

      # Making reference to the objects hierarchy, all locks that
      # are effective on a Dmsf::Entity will be loaded.
      # Note: The lowest locked item will be returned, so if file
      # is locked, and its parent, the parent item's locked will
      # be returned
      #
      # * *Args*    :
      #   - None
      # * *Returns* :
      #   - +[Dmsf::Lock]+ -> Array of effective locks
      #
      def effective_locks
        return @effective_locks unless @effective_locks.nil?
        #This forces an inner join which will only return hierarchy items
        #that have un-expired locks on them (or locks without expiry)

        #Note: we use arel to build the condition
        expires_arel = Dmsf::Lock.arel_table[:expires_at]
        hierarchy = tree_with_locks.where(
          expires_arel.lt(DateTime.now).
          or(expires_arel.eq(nil))
        )
        @effective_locks = []
        hierarchy.each do |entity|
          next if entity.locks.nil? or entity.locks.empty?
          @effective_locks = entity.locks
          break
        end
        return @effective_locks
      end

      # Indicates if the current resource should be considered
      # locked.
      #
      # * *Args*    :
      #   - None
      # * *Returns* :
      #   - +Boolean+ -> Locked (true), Unlocked (false)
      #
      def locked?
        #If effective_locks is empty then return false
        return !effective_locks.empty?
      end

      # Execute a process by where the entity lock is removed,
      # Checks are run on the lock to ensure basic security is
      # preserved (hence why this is in lib not model)
      #
      # Exceptions are raised if criteria is not met for unlock to
      # be successful
      #
      # * *Args*    :
      #   - +user+ -> Optional (User.current utilised when not set)
      # * *Returns* :
      #   - None
      # * *Raises*  :
      #   - +Dmsf::Lockable::ResourceNotLocked+ -> Unlock attempted when item not locked
      #   - +Dmsf::Lockable::ResourceParentLocked+ -> Items in entities Hierarchy are locked
      #   - +Dmsf::Lockable::LockNotOwnedByPrincipal+ -> The lock that would be unlocked by
      #     this request is not owned by person requesting the unlock (user)
      #
      def unlock! (user = nil)
        user ||= User.current
        raise Dmsf::Lockable::ResourceNotLocked,
              l('dmsf_exceptions.resource_not_locked') unless locked?
        raise Dmsf::Lockable::ResourceParentLocked,
              l('dmsf_exceptions.resource_parent_locked') unless effective_locks.first.entity_id == id
        raise Dmsf::Lockable::LockNotOwnedByPrincipal,
              l('dmsf_exceptions.lock_not_owned_by_principal') unless user.id == effective_locks.first.user_id
        effective_locks.first.delete
        @effective_locks = nil #reset internal dictionary
      end

      # Providing that the resource is unlocked, produces and
      # exclusive write lock, otherwise raising an exception
      #
      #
      # * *Args*    :
      #   - +user+   -> User lock is for (Optional: User.current when not set)
      #   - +expiry+ -> Expiry date/time for lock (infinite when not set)
      # * *Returns* :
      #   - +Dmsf::Lock+ -> the created lock
      # * *Raises*  :
      #   - +Dmsf::Lockable::ResourceParentLocked+ -> Indicates that the resource has an inherited lock
      #     enforced upon it.
      #   - +Dmsf::Lockable::ResourceLocked+ -> Indicates that the requested resource is already locked.
      #
      def lock! (user = nil, expiry = nil)
        user ||= User.current
        if locked?
          raise Dmsf::Lockable::ResourceParentLocked,
                l('dmsf_exceptions.resource_parent_locked') unless effective_locks.first.entity_id == id
          raise Dmsf::Lockable::ResourceLocked,
                l('dmsf_exceptions.resource_locked')
        end
        expiry = expiry.to_time if expiry.kind_of?(Date)
        expiry = nil unless expiry.kind_of?(Time)

        lock = locks.create! :lock_scope => Dmsf::Lock.scope_exclusive,
                             :lock_type  => Dmsf::Lock.type_write,
                             :user       => user,
                             :expires_at => expiry
        @effective_locks = nil #Reset internal dictionary
        return lock
      end

      # Indicates if a resource is locked and/or if the resource lock
      # impedes operation for specified user.
      #
      # If a resource is locked, and the lock is owned by current user
      # then it should not be considered as locked to that user, however
      # should to all others
      #
      # * *Args*    :
      #   - +user+ -> Principal for lock-check (Optional: User.current utilised otherwise)
      # * *Returns* :
      #   - +Boolean+ -> Locked (true); Unlocked (false)
      # * *Raises*  :
      #   - +ArgumentError+ -> If user is not a Principal
      #
      def locked_for?(user = nil)
        user ||= User.current
        raise ArgumentError unless user.kind_of?(Principal)
        return false unless locked?
        #Scenario time:
        #If user_a locks a file, then user_b locks the folder,
        #user_b should still be prevented from writing to file
        #that was locked by user_a - effective_locks returns all
        #active locks in play on file ... so if we work our way
        #through that its safe to assume its not locked to them
        effective_locks.each do|lock|
          return true if lock.user_id != user.id
        end
        false
      end
    end
  end
end