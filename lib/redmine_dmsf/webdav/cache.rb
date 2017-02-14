# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Picman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module RedmineDmsf
  module Webdav
    class Cache
      def self.read(name, options = nil)
        init unless defined?(@@WebDAVCache)
        @@WebDAVCache.read(name, options)
      end
      
      def self.write(name, value, options = nil)
        init unless defined?(@@WebDAVCache)
        @@WebDAVCache.write(name, value, options)
      end
      
      def self.delete(name, options = nil)
        init unless defined?(@@WebDAVCache)
        @@WebDAVCache.delete(name, options)
      end
      
      def self.exist?(name, options = nil)
        init unless defined?(@@WebDAVCache)
        @@WebDAVCache.exist?(name, options)
      end
      
      def self.invalidate_item(key)
        init unless defined?(@@WebDAVCache)
        # Write an .invalid entry to notify anyone that is currently creating a response
        # that that response is invalid and should not be cached
        @@WebDAVCache.write("#{key}.invalid", expires_in: 60.seconds)
        # Delete any existing entry in the cache
        @@WebDAVCache.delete(key)
      end
      
      def self.cache
        @@WebDAVCache
      end
      
      def self.init_testcache
        #puts "Webdav::Cache: Enable MemoryStore cache."
        @@WebDAVCache = ActiveSupport::Cache::MemoryStore.new(:namespace => "RedmineDmsfWebDAV")
      end
      
      def self.init_nullcache
        #puts "Webdav::Cache: Disable cache."
        @@WebDAVCache = ActiveSupport::Cache::NullStore.new
      end
      
      private
      
      def self.init
        if Setting.plugin_redmine_dmsf['dmsf_memcached_servers'].nil? || Setting.plugin_redmine_dmsf['dmsf_memcached_servers'].empty?
          # Disable caching by using a null cache
          Rails.logger.info "Webdav::Cache: Cache disabled!"
          @@WebDAVCache = ActiveSupport::Cache::NullStore.new
        else
          # Create cache using the provided server address
          Rails.logger.info "Webdav::Cache: Cache enabled, using memcached server '#{Setting.plugin_redmine_dmsf['dmsf_memcached_servers']}'"
          @@WebDAVCache = ActiveSupport::Cache::MemCacheStore.new(Setting.plugin_redmine_dmsf['dmsf_memcached_servers'])
        end
      end
    end
  end
end