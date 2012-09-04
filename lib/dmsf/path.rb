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
  end
end