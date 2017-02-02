# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

class DmsfFolderTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :users, :email_addresses, :dmsf_folders, :roles, :members, :member_roles
         
  def setup    
    @folder4 = DmsfFolder.find_by_id 4
    @folder5 = DmsfFolder.find_by_id 5
    @folder6 = DmsfFolder.find_by_id 6
  end
  
  def test_truth
    assert_kind_of DmsfFolder, @folder4
    assert_kind_of DmsfFolder, @folder5
    assert_kind_of DmsfFolder, @folder6
  end
    
  def test_delete        
    assert @folder6.delete(false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted?, "Folder #{@folder6} hasn't been deleted"
  end
  
  def test_restore    
    assert @folder6.delete(false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted?, "Folder #{@folder6} hasn't been deleted"
    assert @folder6.restore, @folder6.errors.full_messages.to_sentence
    assert !@folder6.deleted?, "Folder #{@folder6} hasn't been restored"
  end
  
  def test_destroy    
    @folder6.delete true
    assert_nil DmsfFolder.find_by_id(@folder6.id)    
  end

  def test_is_column_on_default
    DmsfFolder::DEFAULT_COLUMNS.each do |column|
      assert DmsfFolder.is_column_on?(column), "The column #{column} is not on?"
    end
  end

  def test_is_column_on_available
    (DmsfFolder::AVAILABLE_COLUMNS - DmsfFolder::DEFAULT_COLUMNS).each do |column|
      assert !DmsfFolder.is_column_on?(column), "The column #{column} is on?"
    end
  end
  
  def test_get_column_position_default
    # 0 - checkbox
    assert_nil DmsfFolder.get_column_position('checkbox'), "The column 'checkbox' is on?"
    # 1 - id
    assert_nil DmsfFolder.get_column_position('id'), "The column 'id' is on?"
    # 2 - title
    assert_equal DmsfFolder.get_column_position('title'), 1, "The expected position of the 'title' column is 2"
    # 3 - extension
    assert_nil DmsfFolder.get_column_position('extensions'), "The column 'extensions' is on?"
    # 4 - size
    assert_equal DmsfFolder.get_column_position('size'), 2, "The expected position of the 'size' column is 4"
    # 5 - modified
    assert_equal DmsfFolder.get_column_position('modified'), 3, "The expected position of the 'modified' column is 5"
    # 6 - version
    assert_equal DmsfFolder.get_column_position('version'), 4, "The expected position of the 'version' column is 6"
    # 7 - workflow
    assert_equal DmsfFolder.get_column_position('workflow'), 5, "The expected position of the 'workflow' column is 7"
    # 8 - author
    assert_equal DmsfFolder.get_column_position('author'), 6, "The expected position of the 'workflow' column is 8"
    # 9 - custom fields
    assert_nil DmsfFolder.get_column_position('Tag'), "The column 'Tag' is on?"
    # 10- commands
    assert_equal DmsfFolder.get_column_position('commands'), 7, "The expected position of the 'commands' column is 10"
    # 11- (position)
    assert_equal DmsfFolder.get_column_position('position'), 8, "The expected position of the 'position' column is 11"
    # 12- (size)
    assert_equal DmsfFolder.get_column_position('size_calculated'), 9,
                 "The expected position of the 'size_calculated' column is 12"
    # 13- (modified)
    assert_equal DmsfFolder.get_column_position('modified_calculated'), 10,
                 "The expected position of the 'modified_calculated' column is 13"
    # 14- (version)
    assert_equal DmsfFolder.get_column_position('version_calculated'), 11,
                 "The expected position of the 'version_calculated' column is 14"
  end

  def test_save_and_destroy_with_cache
    RedmineDmsf::Webdav::Cache.init_testcache
    
    # save
    cache_key = @folder4.propfind_cache_key
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @folder4.save
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    RedmineDmsf::Webdav::Cache.delete("#{cache_key}.invalid")
    
    # destroy
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @folder4.destroy
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    RedmineDmsf::Webdav::Cache.cache.clear
    
    # save!
    cache_key = @folder5.propfind_cache_key
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @folder5.save!
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    RedmineDmsf::Webdav::Cache.delete("#{cache_key}.invalid")
    
    # destroy!
    RedmineDmsf::Webdav::Cache.write(cache_key, "")
    assert RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert !RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    @folder5.destroy!
    assert !RedmineDmsf::Webdav::Cache.exist?(cache_key)
    assert RedmineDmsf::Webdav::Cache.exist?("#{cache_key}.invalid")
    
    RedmineDmsf::Webdav::Cache.init_nullcache
  end

  def test_to_csv
    columns = ['id', 'title']
    csv = @folder4.to_csv(columns, 0)
    assert_equal 2, csv.size
  end
end