module Dmsf
  class Acl

    # Initialization routine for Dmsf::Acl
    # Injects dependency for Acl routines through implementation of
    # @entity
    #
    # * *Args*    :
    #   - +entity+ -> Entity that the Acl class is providing for (DI)
    # * *Returns* :
    #   - void
    # * *Raises* :
    #   - +ArgumentError+ -> if entity is not a Dmsf::Entity
    #
    def initialize(entity)
      raise ArgumentError unless entity.kind_of?(Dmsf::Entity)
      @entity = entity
    end

    # Based on the current scope of the object,
    # determines if the user holds the effective permission
    # Dmsf::Permission::READ and will return true/false based
    # on that, if no user is provided, User.current will be
    # utilised.
    #
    # * *Args*    :
    #   - +user+ -> (Optional: otherwise returns User.current)
    # * *Returns* :
    #   - +Boolean+ -> Visible (true); Hidden (false)
    #
    def visible?(user = nil)
      user ||= User.current
      hierarchy = @entity.self_and_ancestors
      permissions = load_individual_permission(hierarchy, Dmsf::Permission.READ, user)
      inject_to_chain(hierarchy, permissions)
      return check_single_permission_hierarchy(hierarchy)
    end

    # Based on the current scope fo the object, will assess
    # from its hierarchy and its sibling list a set of permissions
    # assessing each for every sibling and providing a filtered list
    # from which the current item will be excluded
    #
    # * *Args*    :
    #   - +user+ -> (Optional: otherwise returns User.current)
    # * *Returns* :
    #   - +[Dmsf::Entity]+ -> An array of Visible siblings
    #
    def visible_siblings(user = nil)
      user ||= User.current
      hierarchy = @entity.ancestors unless @entity.parent_id.nil?
      hierarchy ||= [] #If there is no ancestors (root level for example)
      siblings = @entity.siblings
      permissions = load_individual_permission(hierarchy + siblings, Dmsf::Permission.READ, user)
      inject_to_chain(hierarchy + siblings, permissions)
      siblings.to_a.delete_if {|sibling| !check_single_permission_hierarchy(hierarchy + [sibling])}
    end

    # Identify the current permission-set for the user
    # will evaluate based on current object, the permissions for
    # hierarchy - providing a hash identifying all permission
    # types and if they are permitted (or not)
    #
    # * *Args*    :
    #   - +user+ -> (Optional: otherwise utilises User.current)
    # * *Returns* :
    #   - +Hash+ -> Hash of current permissions
    #
    def permissions_for(user = nil)
      user ||= User.current
      hierarchy = @entity.self_and_ancestors
      permissions = load_all_permissions(hierarchy, user)
      inject_to_chain(hierarchy, permissions)
      return effective_permission_hierarchy(hierarchy)
    end

    # Will evaluate current permission chain on current object and its
    # children - if @entity is not a Dmsf::Folder then the routine will
    # ALWAYS return an empty array as only a Dmsf::Folder can have
    # children
    #
    # * *Args*    :
    #   - +user+ -> (Optional: otherwise utilises User.current)
    # * *Returns* :
    #   - +[Dmsf::Entity]+ -> Array of visible children
    #   - +[]+ -> Empty array when object is not a Dmsf::Folder
    #
    def visible_children(user = nil)
      user ||= User.current
      return [] unless @entity.is_a?(Dmsf::Folder)
      hierarchy = @entity.self_and_ancestors
      children = @entity.children
      permissions = load_individual_permission(hierarchy + children,
                                               Dmsf::Permission.READ,
                                               user)
      inject_to_chain(hierarchy + children, permissions)
      children.to_a.delete_if {|child|
        !check_single_permission_hierarchy(hierarchy + [child])
      }
    end

    protected

    # Retrieves an individual permission scope for specified user
    # based on a pre-loaded scope (eg: @entity.self_and_ancestors)
    #
    # * *Args*    :
    #   - +scope+ -> Scope to which permissions should be effective (ActiveRecord::Relation)
    #   - +perm+  -> Permission we are hunting for (Fixnum)
    #   - +user+  -> User for which permissions should be loaded for
    # * *Returns* :
    #   - Array/Relation containing Dmsf::Permission objects relevant to chain
    #
    def load_individual_permission(scope, perm, user)
      perm = [perm] unless perm.is_a?(Array)
      permissions = load_all_permissions(scope, user)
      perm.each {|p| permissions = permissions.where("#{Dmsf::Permission.table_name}.permission & #{p} = #{p}")}
      return permissions
    end

    # Retrieves all permissions for user based on provided pre-loaded
    # scope (eg: @entity.self_and_ancestors). It is important to note
    # however that the because roles are an effective part of providing
    # permissions, that a users roles are also loaded for evaluation in
    # permission chain.
    #
    # * *Args*    :
    #   - +scope+ -> Scope to which permissions should be effective (ActiveRecord::Relation)
    #   - +user+  -> User for which permissions should be loaded for
    # * *Returns* :
    #   - Array/Relation containing Dmsf::Permission objects relevant to chain
    #
    def load_all_permissions(scope, user)
      roles = cached_roles(user)
      scope = [scope] if scope.kind_of?(Dmsf::Entity)
      dp_table = Dmsf::Permission.table_name
      sql_for_roles = "(#{dp_table}.role_id IN (#{roles.collect(&:id).join(',')}) AND #{dp_table}.user_id IS NULL)"

      #Fix silly bug
      sql_for_roles = '(1 = 0)' if roles.empty?
      sql_for_user  = "(#{dp_table}.user_id = #{user.id} AND #{dp_table}.role_id IS NULL)"
      permissions = Dmsf::Permission.where(:entity_id => scope.collect(&:id)).
                                     where("#{sql_for_roles} OR #{sql_for_user}").
                                     order("#{dp_table}.prevent, #{dp_table}.user_id")
      return permissions
    end

    # It is probably *VERY* important to note that this method is not
    # exactly part of the standard way to do things:
    # In our case eager-loading (via .includes(:permissions)) loads too
    # much information and if you refer to load_all_permissions you'll see
    # that the desired filter is far too complex to relate to a standard
    # has_many set of conditions. Instead we load our permissions, and then
    # inform each object of the proposed relations and allow Rails to do it's
    # own internal work to correctly provide references to object collections
    #
    # * *Args*    :
    #   - +scope+ -> Scope to which permissions should be join (ActiveRecord::Relation)
    #   - +perms+ -> A collection of permissions to be forced on scope
    # * *Returns* :
    #   - +ActiveRecord::Relation+ -> The scope supplied (now that it's had its data pre-loaded)
    #
    def inject_to_chain(scope, perms)
      scope.each {|e|
        assoc = e.association(:permissions)
        assoc.loaded!
        assoc.target.concat(perms)
        perms.each {|p|
          assoc.set_inverse_instance(p)
        }
      }
      return scope
    end

    # Retrieves an User roles however making as much effort to
    # cache internally as possible (mainly to lower query count)
    # Note this requires @entity to contain project information
    #
    # * *Args*    :
    #   - +user+ -> User for whom we're loading roles
    #
    # * *Returns* :
    #   - +Array/Relation+ -> containing Role objects relevant to user
    #
    def cached_roles(user)
      @user_roles ||= {}
      roles = @user_roles[user[:login].to_s]
      return roles unless roles.nil?
      @user_roles[user[:login].to_s] = user.roles_for_project(@entity.project)
    end

    # Logic processing for a hierarchy to determine if a user holds a given
    # permission - this method is very dumb and automatically assumes that
    # the scope has had filters pre-applied, it does no checking to validate
    # so if a scope is entered with 2 permission sets, it will return incorrectly
    #
    # * *Args*    :
    #   - +hierarchy+      -> Scope determining hierarchy of permissions / objects
    #   - +initial_permit+ -> Determine default strategy should no permissions match
    # * *Returns* :
    #   - +Boolean+ -> user should be granted (true) or prevented (false)
    #
    def check_single_permission_hierarchy(hierarchy, initial_permit = true)
      # Some logic rules, so we have them somewhere
      # * If a user based prevent is hit at any point, we immediately enter next level
      # * We take the view Allow,Deny (Allow takes precedence over a deny on roles)
      entity_id = nil; c_perm = initial_permit; ignore_level = false
      level_perms = []
      hierarchy.each do |level|
        l_perm = nil
        #We make a BIG assumption that the hierarchy will pre-load permissions where needed
        #next if !level.permissions.loaded? || level.permissions.empty?
        level.permissions.each do |perm|
          next if perm.nil? #How did we hit this?
          if perm.user_id.nil?
            l_perm = !perm.prevent
            break perm
          else
            l_perm = !perm.prevent unless l_perm
          end
        end
        l_perm = c_perm if l_perm.nil?
        c_perm = l_perm
      end
      return c_perm
    end

    # Evaluates a set of hierarchy assuming that all permissions relevant to a
    # single users User and Roles are loaded into object chain
    #
    # * *Args*    :
    #   - +hierarchy+ -> Current hierarchy chain to be evaluated
    # * *Returns* :
    #   - +Hash+ -> returning all effective permissions
    #
    def effective_permission_hierarchy(hierarchy)
      initial_perms = {:read => true, :write => true, :modify => true, :delete => true, :perms => true}
      c_perm = initial_perms
      hierarchy.each {|level|
        user_perms = []
        role_perms = []
        l_perm = c_perm
        level.permissions.each {|perm|
          user_perms << perm unless perm.user_id.nil?
          role_perms << perm unless perm.role_id.nil?
        }
        #Sort so we get Prevents then Allows
        user_perms.sort! {|x,y|x.prevent.to_s <=> y.prevent.to_s}.reverse!
        role_perms.sort! {|x,y|x.prevent.to_s <=> y.prevent.to_s}.reverse!
        #Go through role based perms
        role_perms.each do |r|
          l_perm.merge!(permission_to_sym( r.permission, !r.prevent))
        end
        user_perms.each do |u|
          l_perm.merge!(permission_to_sym( u.permission, !u.prevent))
        end
        c_perm = l_perm
      }
      return c_perm
    end

    # Converts a permission integer and stance (bool) into a hash
    # of effective permissions:
    # permission_to_sym(Dmsf::Permission.READ | Dmsf::Permission.WRITE, true)
    # would return:
    # { :read => true, :write => true }
    #
    # * *Args*    :
    #   - +perm+   -> The integer value of current permission
    #   - +stance+ -> Boolean to indicate if it is a grant or prevent
    # * *Returns* :
    #   - +Hash+   -> Returning effective permissions and stance
    #
    def permission_to_sym(perm, stance)
      result = {}
      result[:read] = stance if perm & 1 == 1
      result[:write] = stance if perm & 2 == 2
      result[:modify] = stance if perm & 4 == 4
      result[:delete] = stance if perm & 8 == 8
      result[:perms] = stance if perm & 16 == 16
      return result
    end
  end
end