# frozen_string_literal: true

module Dav4rack
  # Lock
  class Lock
    attr_reader :store

    def initialize(args = {})
      @args = args
      @store = nil
      @args[:created_at] = Time.current
      @args[:updated_at] = Time.current
    end

    def store=(store)
      raise TypeError, 'Expecting LockStore' unless store.respond_to? :remove

      @store = store
    end

    def destroy
      @store&.remove self
    end

    def remaining_timeout
      @args[:timeout].to_i - (Time.now.to_i - @args[:created_at].to_i)
    end

    def respond_to_missing?(_name, _include_private)
      true
    end

    def method_missing(*args)
      if @args.key?(args.first.to_sym)
        @args[args.first.to_sym]
      elsif args.first.to_s[-1, 1] == '='
        @args[args.first.to_s[0, args.first.to_s.length - 1].to_sym] = args[1]
      else
        raise NoMethodError, "Undefined method #{args.first} for #{self}"
      end
    end
  end
end
