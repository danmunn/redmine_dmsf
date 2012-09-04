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

    #We're overriding the function from awesome_nested set, because it queries
    #based on object existing, if it doesn't a != null returns no results (so it'd seem)
    def without_self(scope)
      verb = self[self.class.primary_key] === nil ? 'IS NOT' : '!='
      scope.where(["#{self.class.quoted_table_name}.#{self.class.quoted_primary_key} #{verb} ?", self])
    end

    def path
      #Test requires we return an array, so we convert the ActiveRecord::Relation
      #into an enumerator through return of map object, however we want all objects
      #as are, although only returns if the object has an id
      r_path = Dmsf::Path.new
      unless self.id === nil
        self_and_ancestors.each{|x|r_path << x}
        return r_path
      end

      #As the item does not yet exist, it cannot have a sql based hierarchy,
      #so we reference the hierarchy for its parent and push the object on the
      #end, creating a proper array snapshot of the path.
      begin
        parent.self_and_ancestors.each{|x|r_path << x}
      rescue
        #Nothing to rescue here, if there is no parent, we can't map path, and the end element
        #should always be the current
      end
      r_path.push(self)
      return r_path
    end

    protected
    def validate_name_uniqueness
      #reference project identified in model
      project_id = self.project === nil ? nil : self.project.id
      return true unless siblings.where(:title => self.title, :project_id => project_id).count > 0
      errors.add(:entity, l(:error_create_entity_uniqueness))
      return false
    end
  end
end