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

    # Expired?
    # --------
    # Returns a boolean value to indicate if the current Lock has
    # expired or not.
    #
    # @return bool
    def expired?
      return false if expires_at.nil?
      return expires_at <= Time.now
    end

    # delete_expired
    # Utilising the scope "expired", a delete operation is called
    #
    # @return void
    def self.delete_expired
      self.expired.delete_all
    end

    # find
    # Overload the existing implementation of find to take a string
    # value (and integer) and act similarly to a factory in determing
    # best path of execution
    #
    # @return Dmsf::Lock (or nil)
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
    def generate_uuid
      self.uuid = UUIDTools::UUID.timestamp_create().to_s
    end
  end
end
