module Dmsf
  class Entity < Dmsf::ActiveRecordBase
    acts_as_nested_set
    belongs_to :project
    belongs_to :owner, :class_name => "User"
    belongs_to :deleted_by, :class_name => "User"

    validates_presence_of :collection, :title, :owner_id, :project_id
  end
end