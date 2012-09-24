module Dmsf
  module Audit
    class Base < ActiveRecord::Base
      self.table_name = 'dmsf_audit'
      belongs_to :relation, :polymorphic => true
      belongs_to :user
      serialize :meta, OpenStruct
    end
  end
end