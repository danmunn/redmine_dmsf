module Dmsf
  class ActiveRecordBase < ActiveRecord::Base
    self.table_name_prefix = "dmsf_"
    self.abstract_class = true
    @columns = []
  end
end