# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
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

desc <<-END_DESC
Clears the Webdav Cache

Example:
  rake redmine:dmsf_clear_webdav_cache RAILS_ENV="production"
END_DESC
  
namespace :redmine do
  task :dmsf_clear_webdav_cache => :environment do    
    DmsfWebdavCache.clear
  end
end

class DmsfWebdavCache
  def self.clear
    if Setting.plugin_redmine_dmsf['dmsf_memcached_servers'].nil? || Setting.plugin_redmine_dmsf['dmsf_memcached_servers'].empty?
      puts 'No memcached server configured.'
    else
      puts "Clearing memcached at '#{Setting.plugin_redmine_dmsf['dmsf_memcached_servers']}'"
      cache = ActiveSupport::Cache::MemCacheStore.new(Setting.plugin_redmine_dmsf['dmsf_memcached_servers'])
      cache.clear
    end
  end
end
