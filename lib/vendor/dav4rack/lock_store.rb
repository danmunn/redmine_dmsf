require 'dav4rack/lock'
module DAV4Rack
  class LockStore
    class << self
      def create
        @locks_by_path = {}
        @locks_by_token = {}
      end
      def add(lock)
        @locks_by_path[lock.path] = lock
        @locks_by_token[lock.token] = lock
      end
      
      def remove(lock)
        @locks_by_path.delete(lock.path)
        @locks_by_token.delete(lock.token)
      end
    
      def find_by_path(path)
        @locks_by_path.map do |lpath, lock|
          lpath == path && lock.remaining_timeout > 0 ? lock : nil
        end.compact.first
      end
      
      def find_by_token(token)
        @locks_by_token.map do |ltoken, lock|
          ltoken == token && lock.remaining_timeout > 0 ? lock : nil
        end.compact.first
      end
      
      def explicit_locks(path)
        @locks_by_path.map do |lpath, lock|
          lpath == path && lock.remaining_timeout > 0 ? lock : nil
        end.compact
      end
      
      def implicit_locks(path)
        @locks_by_path.map do |lpath, lock|
          lpath =~ /^#{Regexp.escape(path)}/ && lock.remaining_timeout > 0 && lock.depth > 0 ? lock : nil
        end.compact
      end
      
      def explicitly_locked?(path)
        self.explicit_locks(path).size > 0
      end
      
      def implicitly_locked?(path)
        self.implicit_locks(path).size > 0
      end
      
      def generate(path, user, token)
        l = Lock.new(:path => path, :user => user, :token => token)
        l.store = self
        add(l)
        l
      end
    end
  end
end

DAV4Rack::LockStore.create