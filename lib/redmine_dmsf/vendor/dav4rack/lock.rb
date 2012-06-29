module DAV4Rack
  class Lock
    
    def initialize(args={})
      @args = args
      @store = nil
      @args[:created_at] = Time.now
      @args[:updated_at] = Time.now
    end
    
    def store
      @store
    end
    
    def store=(s)
      raise TypeError.new 'Expecting LockStore' unless s.respond_to? :remove
      @store = s
    end
    
    def destroy
      if(@store)
        @store.remove(self)
      end
    end
    
    def remaining_timeout
      @args[:timeout].to_i - (Time.now.to_i - @args[:created_at].to_i)
    end
    
    def method_missing(*args)
      if(@args.has_key?(args.first.to_sym))
        @args[args.first.to_sym]
      elsif(args.first.to_s[-1,1] == '=')
        @args[args.first.to_s[0, args.first.to_s.length - 1].to_sym] = args[1]
      else
        raise NoMethodError.new "Undefined method #{args.first} for #{self}"
      end
    end
  end
end