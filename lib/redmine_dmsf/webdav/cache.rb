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
        Rails.cache.read(name, options)
      end

      def self.write(name, value, options = nil)
        Rails.cache.write(name, value, options)
      end

      def self.delete(name, options = nil)
        Rails.cache.delete(name, options)
      end

      def self.exist?(name, options = nil)
        Rails.cache.exist?(name, options)
      end

      def self.clear
        Rails.cache.clear
      end
      
      def self.invalidate_item(key)
        return if key.blank?
        # Write an .invalid entry to notify anyone that is currently creating a response
        self.write("#{key}.invalid", expires_in: 60.seconds)
        # Delete any existing entry in the cache
        self.delete(key)
      end

    end
  end
end