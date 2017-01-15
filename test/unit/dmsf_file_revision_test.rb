# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

require File.expand_path('../../test_helper', __FILE__)

class DmsfFileRevisionTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :users, :email_addresses, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :roles, :members,
           :member_roles, :enabled_modules, :enumerations, :dmsf_locks
         
  def setup
    @revision1 = DmsfFileRevision.find_by_id 1
    @revision2 = DmsfFileRevision.find_by_id 2
    @revision5 = DmsfFileRevision.find_by_id 5
  end
  
  def test_truth
    assert_kind_of DmsfFileRevision, @revision1
    assert_kind_of DmsfFileRevision, @revision2
    assert_kind_of DmsfFileRevision, @revision5
  end
  
  def test_delete_restore      
    @revision5.delete false    
    assert @revision5.deleted?, 
      "File revision #{@revision5.name} hasn't been deleted"
    @revision5.restore    
    assert !@revision5.deleted?, 
      "File revision #{@revision5.name} hasn't been restored"
  end    
  
  def test_destroy       
    @revision5.delete true
    assert_nil DmsfFileRevision.find_by_id @revision5.id    
  end

  def test_create_digest
    assert_equal @revision5.create_digest, 0, "MD5 should be 0, if the file is missing"
  end
  
  def test_save_and_destroy_with_cache
    RedmineDmsf::Webdav::Cache.init_testcache
    
    # save
    cache_key = @revision1.propfind_cache_key
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @revision1.save
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    RedmineDmsf::Webdav::Cache.delete("#{cache_key}.invalid")
    
    # destroy
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @revision1.destroy
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    
    # save!
    cache_key = @revision2.propfind_cache_key
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @revision2.save!
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    
    RedmineDmsf::Webdav::Cache.init_nullcache
  end

end