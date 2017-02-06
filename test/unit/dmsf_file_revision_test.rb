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
  
  def test_new_storage_filename
    # Create a file.
    f = DmsfFile.new
    f.container_type = 'Project'
    f.container_id = 1
    f.name = "Testfile.txt"
    f.dmsf_folder = nil
    f.notification = !Setting.plugin_redmine_dmsf['dmsf_default_notifications'].blank?
    f.save
    
    # Create two new revisions, r1 and r2
    r1 = DmsfFileRevision.new
    r1.minor_version = 0
    r1.major_version = 1
    r1.dmsf_file = f
    r1.user = User.current
    r1.name = "Testfile.txt"
    r1.title = DmsfFileRevision.filename_to_title("Testfile.txt")
    r1.description = nil
    r1.comment = nil
    r1.mime_type = nil
    r1.size = 4
    
    r2 = r1.clone
    r2.minor_version = 1
    
    assert r1.valid?
    assert r2.valid?
    
    # This is a very stupid since the generation and storing of files below must be done during the
    # same second, so wait until the microsecond part of the DateTime is less than 10 ms, should be
    # plenty of time to do the rest then.
    wait_timeout = 2000
    while (DateTime.now.usec > 10*1000)
        wait_timeout -= 10
        if wait_timeout <= 0
            flunk "Waited too long."
        end
        sleep 0.01
    end
    
    # First, generate the r1 storage filename and save the file
    r1.disk_filename = r1.new_storage_filename
    assert r1.save
    # Just make sure the file exists
    File.open(r1.disk_file, 'wb') do |f|
        f.write("1234")
    end
    
    # Directly after the file has been stored generate the r2 storage filename.
    # Hopefully the seconds part of the DateTime.now has not changed and the generated filename will
    # be on the same second but it should then be increased by 1.
    r2.disk_filename = r2.new_storage_filename
    
    assert_not_equal r1.disk_filename, r2.disk_filename, "The disk filename should not be equal for two revisions."
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