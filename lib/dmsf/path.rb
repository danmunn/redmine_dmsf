module Dmsf
  class Path < Array
    def push *input
      if input.kind_of?(Array) || input.kind_of?(Dmsf::Path)
        input.each{|x|
          raise(ArgumentError, 'expected Dmsf::Entity object' ) unless x.kind_of?(Dmsf::Entity)
        }
      else
        raise(ArgumentError, 'expected Dmsf::Entity object' ) unless input.kind_of?(Dmsf::Entity)
      end
      return Array.instance_method(:push).bind(self).call *input
    end

    def << (input)
      sym = '<<'.to_sym
      raise(ArgumentError, 'expected Dmsf::Entity object' ) unless input.kind_of?(Dmsf::Entity)
      return Array.instance_method(sym).bind(self).call input
    end

    def to_s
      return '' if self.length == 0
      return self.map{|x| x.title} * '/'
    end

    def is_orphan?
      return false if self.length == 0 ||
          self[0].parent_id == nil
      true
    end

    def is_valid?
      return true if self.length == 0
      parent_id = nil
      self.each {|e|
        return false unless e.parent_id == parent_id
        parent_id = e.id
      }
      return true
    end

    ## @param input String
    def self.find input, project
      return nil unless input.length > 2 && input[0..0] == '/'

      path = Dmsf::Path.new
      parts = input.gsub(/^[\/]+|[\/]+$/, '').split '/'
      root = Dmsf::Entity.roots.where(:title => parts.shift,
                                      :project_id => project,
                                      :deleted => false).first
      return nil if root === nil

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