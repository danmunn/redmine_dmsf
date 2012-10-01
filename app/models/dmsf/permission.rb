module Dmsf
  class Permission < Dmsf::ActiveRecordBase

    belongs_to :entity

    scope :perm, lambda {|p| where(["#{self.table_name}.permission ~ #{p} = #{p}"])}

    #Constants
    def self.READ; return 1; end
    def self.WRITE; return 2; end
    def self.MODIFY; return 4; end
    def self.DELETE; return 8; end
    def self.ASSIGN; return 16; end

  end
end