module Dmsf
  class Path < Array

    # Overload the array implementation of push, to ensure objects added
    # are only of the type Dmsf::Entity
    #
    # Adds item to end of array
    #
    # * *Args*    :
    #   - +input+ -> Either single or Array of Dmsf::Entity objects
    # * *Returns* :
    #   - +Dmsf::Path+ -> reference to self
    # * *Exceptions* :
    #   - +ArgumentError+ -> when input is not of type Dmsf::Entity
    #
    def push *input
      input.each{|x|
        raise(ArgumentError, 'expected Dmsf::Entity object' ) unless x.kind_of?(Dmsf::Entity)
      }
      return Array.instance_method(:push).bind(self).call *input
    end

    # Overload the array implementation of <<, to ensure objects added
    # are only of the type Dmsf::Entity
    #
    # Adds item to end of array
    #
    # * *Args*    :
    #   - +input+ -> Either single or Array of Dmsf::Entity objects
    # * *Returns* :
    #   - +Dmsf::Path+ -> reference to self
    # * *Exceptions* :
    #   - +ArgumentError+ -> when input is not of type Dmsf::Entity
    #
    def << (input)
      sym = '<<'.to_sym
      raise(ArgumentError, 'expected Dmsf::Entity object' ) unless input.kind_of?(Dmsf::Entity)
      return Array.instance_method(sym).bind(self).call input
    end

    # Converts current path into a string representation
    #
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +String+ -> Path (eg: folder/subfolder/file.name)
    #
    def to_s
      return '' if self.length == 0
      return self.map{|x| x.title} * '/'
    end

    # Determines if path starts from root (parent_id == nil)
    #  will return true when path starts anywhere but root
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Boolean+ -> Orphan (true); Not an orphan (false)
    #
    def is_orphan?
      return false if self.length == 0 ||
          self[0].parent_id == nil
      true
    end

    # Iterates over the array of Dmsf::Entity to ensure that all object
    # references match up, so that there is not a hidden orphan within chain
    # Will return false if the data appears to make no sense.
    #
    #
    # * *Args*    :
    #   - None
    # * *Returns* :
    #   - +Boolean+ -> Valid (true); Invalid (false)
    #
    def is_valid?
      return true if self.length == 0
      parent_id = nil
      self.each {|e|
        return false unless e.parent_id == parent_id
        parent_id = e.id
      }
      return true
    end

    # Breaks path into usable chunks of information and will attempt to perform
    # a best-effort search on Dmsf::Entity to return the correct hierarchy for search
    # a requirement for the project to search is present.
    #
    # * *Args*    :
    #   - +input+   -> String representation of path.
    #   - +project+ -> Reference to project to be searched.
    # * *Returns* :
    #   - +Dmsf::Path+ -> Path of objects based on searched for path.
    #   - +nil+ -> When nothing matches requested path.
    #
    def self.find input, project
      return nil unless input.length > 2

      path = Dmsf::Path.new
      parts = input.gsub(/^[\/]+|[\/]+$/, '').split '/'
      root_title= parts.shift
      root = Dmsf::Entity.roots.where(:title => root_title,
                                      :project_id => project,
                                      :deleted => false).first
      return nil if root === nil
      return nil unless root.title === root_title #Ensure they are the same

      #Root goes into built path
      path << root
      parent_id = root.id

      #There is no point using the query if our search is only one level deep
      if parts.length > 0
        nodes = root.descendants.where(:deleted => false).map{|x|x} #Convert this into an array, to prevent
                                                                    #accidental data interaction
        parts.each {|e|
          #Iterate through nodes
          found = nodes.reject{|n| n.title != e && n.parent_id != parent_id}.first
          return nil if found.nil? #Path in its entirety is not found, we bail
          nodes.delete_if {|n|n.parent_id == parent_id} #Might as well shrink the array too :)
          parent_id = found.id
          path << found
        }
      end
      return path
    end
  end
end