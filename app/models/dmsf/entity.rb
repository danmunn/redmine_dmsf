module Dmsf
  class Entity < Dmsf::ActiveRecordBase
    acts_as_nested_set
    belongs_to :project
    belongs_to :owner, :class_name => "User"
    belongs_to :deleted_by, :class_name => "User"

    before_create :validate_name_uniqueness

    validates_presence_of :title, :owner_id, :project_id
    validates_format_of :title, :with => /\A[^\/\\\?":<>]*\z/
    validates_presence_of :deleted_by_id, :if => 'deleted == true'
    validates_presence_of :deleted, :if => 'deleted_by_id != nil'
    validate :validate_name_uniqueness

    protected
    def validate_name_uniqueness
      return true unless siblings.where(:title => self.title).count > 0
      errors.add(:entity, l(:error_create_entity_uniqueness))
      return false
    end
  end
end