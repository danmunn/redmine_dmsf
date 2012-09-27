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

      # tree_with_locks
      # ---------------
      # Returns ActiveRecord::Relation with all locks included
      # for hierarchy
      def tree_with_locks
        return @tree_with_locks unless @tree_with_locks.nil?
        @tree_with_locks = self.self_and_ancestors.includes(:locks)
      end

      def reload(*args)
        @tree_with_locks = nil
        @effective_locks = nil
        super *args
      end

      # effective_locks
      # ---------------
      # Retrieves the hierarchy and
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

      # locked?
      # -------
      # Indicates if the item is locked
      # (makes use of effective_locks)
      def locked?
        #If effective_locks is empty then return false
        return !effective_locks.empty?
      end

      # unlock!
      # -------
      # If resource is locked, deletes lock
      # otherwise raises an exception
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

      # lock!
      # -----
      # If resource is unlocked, produces exclusive
      # write lock, otherwise raises exception
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
      end

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