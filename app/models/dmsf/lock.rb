# == Schema Information
#
# Table name: dmsf_locks
#
#  id         :integer          primary key
#  entity_id  :integer
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  type_cd    :integer
#  scope_cd   :integer
#  uuid       :string(36)
#  expires_at :datetime
#

module Dmsf
  class Lock < Dmsf::ActiveRecordBase

    before_create :generate_uuid
    belongs_to :user
    belongs_to :entity
    scope :expired, where(["#{self.quoted_table_name}.expires_at IS NOT NULL AND
                            #{self.quoted_table_name}.expires_at < ?", Time.now])

    as_enum :lock_type, [:type_write, :type_other], :column => :type_cd
    as_enum :lock_scope, [:scope_exclusive, :scope_shared], :column => :scope_cd

    # Returns a boolean value to indicate if the current Lock is
    # expired (true) or not (false).
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Boolean+ -> Determining expiration
    #
    def expired?
      return false if expires_at.nil?
      return expires_at <= Time.now
    end

    # Utilising the scope "expired", a delete_all operation is called.
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - None
    #
    def self.delete_expired
      self.expired.delete_all
    end

    # Overload the existing find implementation provided by ActiveRecord::Base
    # to take either a string value (or integer id) and act similarly to a factory
    # in determining the best path to search for lock.
    #
    # * *Args*    :
    #   - +any+ -> String or Any
    # * *Returns* :
    #   - +ActiveRecord::Relation+ -> When multiple Id's are provided
    #   - +Dmsf::Lock+             -> When Id or UUID is provided
    # * *Raises* :
    #   - +ActiveRecord::RecordNotFound+ -> If nothing matches criteria
    #
    def self.find(*args)
      if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
        lock = find_by_uuid(*args)
        raise ActiveRecord::RecordNotFound, "Couldn't find lock with uuid=#{args.first}" if lock.nil?
        lock
      else
        super
      end
    end

    private

    # Utilising UUIDTools, generate a UUID timestamp for the lock being created.
    # The created UUID is assigned to self.uuid.
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +String+ -> UUID String
    #
    def generate_uuid
      self.uuid = UUIDTools::UUID.timestamp_create().to_s
    end
  end
end
