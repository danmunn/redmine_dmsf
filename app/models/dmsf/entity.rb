# == Schema Information
#
# Table name: dmsf_entities
#
#  id            :integer          not null, primary key
#  project_id    :integer          not null
#  parent_id     :integer
#  title         :string(255)      not null
#  description   :text
#  notification  :boolean          default(FALSE), not null
#  owner_id      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  lft           :integer
#  rgt           :integer
#  depth         :integer
#  type          :string(255)
#  deleted_by_id :integer
#  deleted       :boolean          default(FALSE), not null
#

module Dmsf
  class Entity < Dmsf::ActiveRecordBase
    acts_as_nested_set
    belongs_to :project
    belongs_to :owner, :class_name => "User"
    belongs_to :deleted_by, :class_name => "User"
    belongs_to :parent, :class_name => 'Entity'
    has_many :permissions

    validates_uniqueness_of :title, :scope => [:project_id, :parent_id]
    validates_presence_of :title, :owner_id, :project_id
    validates_format_of :title, :with => /\A[^\/\\\?":<>]*\z/
    validates_presence_of :deleted_by_id, :if => 'deleted == true'
    validates_presence_of :deleted, :if => 'deleted_by_id != nil'

    include Dmsf::Lockable

    # Overrides function that is included by awesome_nested_set
    # Assumption is made through the code that an object exists, and
    # in the case where it does not returns an SQL fragment with != NULL
    # which should be IS NOT NULL
    #
    # * *Args*    :
    #   - +scope+ -> Scope that is being executed upon
    # * *Returns* :
    #   - +ActiveRecord::Relation+ -> Scope, with extended where statement
    #
    def without_self(scope)
      verb = self[self.class.primary_key] === nil ? 'IS NOT' : '!='
      scope.where(["#{self.class.quoted_table_name}.#{self.class.quoted_primary_key} #{verb} ?", self])
    end

    # Instantiates a new copy of Dmsf::Path and populates it
    # with objects hierarchy
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Dmsf::Path+ -> Hierarchy converted into Dmsf::Path object
    #
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

    # Loading of Acl functionality for Dmsf::Entity objects
    # Effectively instantiates a copy of Dmsf::Acl, referencing
    # self (Dmsf::Entity object)
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Dmsf::Acl+ -> Instance for entity
    #
    def Acl
      return @acl unless @acl.nil?
      @acl = Dmsf::Acl.new(self)
    end

    # Overload ActiveRecord::Base implementation of reload
    # with ours providing a reset and then calling on the
    # overloaded method to ensure functionality is preserved.
    #
    # We are resetting @acl (causing new Acl object to be loaded)
    # instantly clearing any and all caches.
    #
    # * *Args*    :
    #   - any
    # * *Returns* :
    #   - None
    #
    def reload(*args)
      @acl = nil
      super *args
    end
  end
end
