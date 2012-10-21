require 'logger'

module DAV4Rack
  # This is a simple wrapper for the Logger class. It allows easy access 
  # to log messages from the library.
  class Logger
    class << self
      # args:: Arguments for Logger -> [path, level] (level is optional) or a Logger instance
      # Set the path to the log file.
      def set(*args)
        if(%w(info debug warn fatal).all?{|meth| args.first.respond_to?(meth)})
          @@logger = args.first
        elsif(args.first.respond_to?(:to_s) && !args.first.to_s.empty?)
          @@logger = ::Logger.new(args.first.to_s, 'weekly')
        elsif(args.first)
          raise 'Invalid type specified for logger'
        end
        if(args.size > 1)
          @@logger.level = args[1]
        end
      end
      
      def method_missing(*args)
        if(defined? @@logger)
          @@logger.send *args
        end
      end
    end
  end
end
