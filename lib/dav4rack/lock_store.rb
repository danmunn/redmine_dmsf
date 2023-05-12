# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/lock"

module Dav4rack
  # Lock store
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
        @locks_by_path.delete lock.path
        @locks_by_token.delete lock.token
      end

      def find_by_path(path)
        @locks_by_path.filter_map { |lpath, lock| lpath == path && lock.remaining_timeout.positive? ? lock : nil }
                      .first
      end

      def find_by_token(token)
        @locks_by_token.filter_map do |ltoken, lock|
          ltoken == token && lock.remaining_timeout.positive? ? lock : nil
        end.first
      end

      def explicit_locks(path)
        @locks_by_path.filter_map { |lpath, lock| lpath == path && lock.remaining_timeout.positive? ? lock : nil }
      end

      def implicit_locks(path)
        @locks_by_path.filter_map do |lpath, lock|
          lpath =~ /^#{Regexp.escape(path)}/ && lock.remaining_timeout.positive? && lock.depth.positive? ? lock : nil
        end
      end

      def explicitly_locked?(path)
        !explicit_locks(path).empty?
      end

      def implicitly_locked?(path)
        !implicit_locks(path).empty?
      end

      def generate(path, user, token)
        l = Lock.new(path: path, user: user, token: token)
        l.store = self
        add l
        l
      end
    end
  end
end

Dav4rack::LockStore.create
