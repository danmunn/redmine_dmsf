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
      private
      def all_locks
        return @locks unless @locks.nil?
      end
    end
  end
end