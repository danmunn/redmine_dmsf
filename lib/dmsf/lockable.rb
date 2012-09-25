module Dmsf
  module Lockable
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

      # effective_locks
      # ---------------
      # Retrieves the hierarchy and
      def effective_locks
        return @effective_locks unless @effective_locks.nil?
        #This forces an inner join which will only return hierarchy items
        #that have un-expired locks on them
        hierarchy = tree_with_locks.where('dmsf_locks.expires_at < :now', :now => DateTime.now)
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
    end
  end
end