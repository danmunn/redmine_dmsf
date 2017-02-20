# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

require File.expand_path('../../../test_helper', __FILE__)
require 'fileutils'

class DmsfWebdavPutTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    DmsfLock.delete_all # Delete all locks that are in our test DB - probably not safe but ho hum
    timestamp = DateTime.now.strftime("%y%m%d%H%M")
    DmsfFile.storage_path = File.expand_path("./dmsf_test-#{timestamp}", DmsfHelper.temp_dir)
    Dir.mkdir(DmsfFile.storage_path) unless File.directory?(DmsfFile.storage_path)
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @role = Role.find 1 #
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = false
    super
  end

  def teardown
    # Delete our tmp folder
    begin
      FileUtils.rm_rf DmsfFile.storage_path
    rescue Exception => e
      error e.message
    end
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Role, @role
  end

  def test_put_denied_unless_authenticated_root
    put '/dmsf/webdav'
    assert_response 401
  end

  def test_put_denied_unless_authenticated
    put "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
  end

  def test_put_denied_with_failed_authentication_root
    put '/dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  def test_put_denied_with_failed_authentication
    put "/dmsf/webdav/#{@project1.identifier}", nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  def test_put_denied_at_root_level
    put '/dmsf/webdav/test.txt', '1234', @admin.merge!({:content_type => :text})
    assert_response :error # 501
  end

  def test_put_denied_on_folder
    put "/dmsf/webdav/#{@project1.identifier}", '1234', @admin.merge!({:content_type => :text})
    assert_response :forbidden
  end

  def test_put_failed_on_non_existant_project
    put '/dmsf/webdav/not_a_project/file.txt', '1234', @admin.merge!({:content_type => :text})
    assert_response 409 # Conflict, not_a_project does not exist - file.txt cannot be created
  end

  def test_put_as_admin_granted_on_dmsf_enabled_project
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @admin.merge!({:content_type => :text})
      assert_response :success # 201 Created
      # Lets check for our file
      file = DmsfFile.find_file_by_name @project1, nil, 'test-1234.txt'
      assert file, 'Check for files existance'
      Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
      if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
        project1_uri = URI.encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1), /\W/)
        put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @admin.merge!({:content_type => :text})
        assert_response 409
        put "/dmsf/webdav/#{project1_uri}/test-1234.txt", '1234', @admin.merge!({:content_type => :text})
        assert_response :success # 201 Created
      end
    end
  end

  def test_put_failed_as_jsmith_on_non_dmsf_enabled_project
    put "/dmsf/webdav/#{@project2.identifier}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
    assert_response 409 # Should report conflict, as project 2 technically doesn't exist if not enabled
    # Lets check for our file
    file = DmsfFile.find_file_by_name @project2, nil, 'test-1234.txt'
    assert_nil file, 'Check for files existance'
  end

  def test_put_failed_when_no_permission
    @project2.enable_module! :dmsf # Flag module enabled
    put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
    assert_response 409 # We don't hold the permission view_dmsf_folders, and thus project 2 doesn't exist to us.
  end

  def test_put_failed_when_no_file_manipulation_permission
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      @project1.enable_module! :dmsf # Flag module enabled
      @role.add_permission! :view_dmsf_folders
      put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
      assert_response :forbidden # We don't hold the permission file_manipulation - so we're unable to do anything with files
    end
  end

  def test_put_failed_when_no_view_dmsf_folders_permission
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :file_manipulation
    # Check we don't have write access even if we do have the file_manipulation permission
    put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
    assert_response 409 # We don't hold the permission view_dmsf_folders, and thus project 2 doesn't exist to us.
    # Lets check for our file
    file = DmsfFile.find_file_by_name @project1, nil, 'test-1234.txt'
    assert_nil file, 'File test-1234 was found in projects dmsf folder.'
  end

  def test_put_succeeds_for_non_admin_with_correct_permissions
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_manipulation
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
      assert_response :success # 201 - Now we have permissions
      # Lets check for our file
      file = DmsfFile.find_file_by_name @project1, nil, 'test-1234.txt'
      assert file, 'File test-1234 was not found in projects dmsf folder.'
      Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
      if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
        project1_uri = URI.encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1), /\W/)
        put "/dmsf/webdav/#{@project1.identifier}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response 409
        put "/dmsf/webdav/#{project1_uri}/test-1234.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response :success # 201 - Now we have permissions
      end
    end
  end

  def test_put_writes_revision_successfully_for_unlocked_file
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      @project1.enable_module! :dmsf #Flag module enabled
      @role.add_permission! :view_dmsf_folders
      @role.add_permission! :file_manipulation
      file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
      assert_not_nil file, 'test.txt file not found'
      assert_difference 'file.dmsf_file_revisions.count', +1 do
        put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response :success # 201 - Created
      end
    end
  end

  def test_put_fails_revision_when_file_is_locked
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_manipulation
    log_user 'admin', 'admin' # login as admin
    assert !User.current.anonymous?, 'Current user is not anonymous'
    file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
    assert file.lock!, "File failed to be locked by #{User.current.name}"
    assert_no_difference 'file.dmsf_file_revisions.count' do
      put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @jsmith.merge!({:content_type => :text})
      assert_response 423 # Locked
    end
  end

  def test_put_fails_revision_when_file_is_locked_and_user_is_administrator
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_manipulation
    log_user 'jsmith', 'jsmith' # login as jsmith
    assert !User.current.anonymous?, 'Current user is not anonymous'
    file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
    assert file.lock!, "File failed to be locked by #{User.current.name}"
    assert_no_difference 'file.dmsf_file_revisions.count' do
      put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @admin.merge!({:content_type => :text})
      assert_response 423 # Locked
    end
  end

  def test_put_accepts_revision_when_file_is_locked_and_user_is_same_as_lock_holder
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      @project1.enable_module! :dmsf # Flag module enabled
      @role.add_permission! :view_dmsf_folders
      @role.add_permission! :file_manipulation
      
      log_user 'jsmith', 'jsmith' # login as jsmith
      assert !User.current.anonymous?, 'Current user is not anonymous'
      file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
      assert l=file.lock!, "File failed to be locked by #{User.current.name}"
      assert_equal file.last_revision.id, l.dmsf_file_last_revision_id
      
      # First PUT should always create new revision.
      assert_difference 'file.dmsf_file_revisions.count', +1 do
        put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response :success # 201 - Created
      end
      # Second PUT on a locked file should only update the revision that were created on the first PUT
      assert_no_difference 'file.dmsf_file_revisions.count' do
        put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response :success # 201 - Created
      end
      # Unlock
      assert file.unlock!, "File failed to be unlocked by #{User.current.name}"

      # Lock file again, but this time delete the revision that were stored in the lock
      file = DmsfFile.find_file_by_name @project1, nil, 'test.txt'
      assert l=file.lock!, "File failed to be locked by #{User.current.name}"
      assert_equal file.last_revision.id, l.dmsf_file_last_revision_id
      
      # Delete the last revision, the revision that were stored in the lock.
      file.last_revision.delete(true)
      
      # First PUT should always create new revision.
      assert_difference 'file.dmsf_file_revisions.count', +1 do
        put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response :success # 201 - Created
      end
      # Second PUT on a locked file should only update the revision that were created on the first PUT
      assert_no_difference 'file.dmsf_file_revisions.count' do
        put "/dmsf/webdav/#{@project1.identifier}/test.txt", '1234', @jsmith.merge!({:content_type => :text})
        assert_response :success # 201 - Created
      end
    end
  end
  
  def test_put_ignored_files_default
    # Ignored patterns: /^(\._|\.DS_Store$|Thumbs.db$)/
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      @project1.enable_module! :dmsf
      @role.add_permission! :view_dmsf_folders
      @role.add_permission! :file_manipulation
      put "/dmsf/webdav/#{@project1.identifier}/._test.txt", '1234', @admin.merge!({:content_type => :text})
      assert_response 204 # NoContent
      put "/dmsf/webdav/#{@project1.identifier}/.DS_Store", '1234', @admin.merge!({:content_type => :text})
      assert_response 204 # NoContent
      put "/dmsf/webdav/#{@project1.identifier}/Thumbs.db", '1234', @admin.merge!({:content_type => :text})
      assert_response 204 # NoContent
      Setting.plugin_redmine_dmsf['dmsf_webdav_ignore'] = '.dump$'
      put "/dmsf/webdav/#{@project1.identifier}/test.dump", '1234', @admin.merge!({:content_type => :text})
      assert_response 204 # NoContent
    end
  end
  
  def test_put_non_versioned_files
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      @project1.enable_module! :dmsf
      @role.add_permission! :view_dmsf_folders
      @role.add_permission! :file_manipulation

      put "/dmsf/webdav/#{@project1.identifier}/file1.tmp", '1234', @admin.merge!({:content_type => :text})
      assert_response :success
      file1 = DmsfFile.find_file_by_name @project1, nil, 'file1.tmp'
      assert_difference 'file1.dmsf_file_revisions.count', 0 do
          put "/dmsf/webdav/#{@project1.identifier}/file1.tmp", '5678', @admin.merge!({:content_type => :text})
          assert_response :success # 201 - Created
      end
      assert_difference 'file1.dmsf_file_revisions.count', 0 do
          put "/dmsf/webdav/#{@project1.identifier}/file1.tmp", '9ABC', @admin.merge!({:content_type => :text})
          assert_response :success # 201 - Created
      end

      put "/dmsf/webdav/#{@project1.identifier}/~$file2.txt", '1234', @admin.merge!({:content_type => :text})
      assert_response :success
      file2 = DmsfFile.find_file_by_name @project1, nil, '~$file2.txt'
      assert_difference 'file1.dmsf_file_revisions.count', 0 do
          put "/dmsf/webdav/#{@project1.identifier}/~$file2.txt", '5678', @admin.merge!({:content_type => :text})
          assert_response :success # 201 - Created
      end
      assert_difference 'file1.dmsf_file_revisions.count', 0 do
          put "/dmsf/webdav/#{@project1.identifier}/~$file2.txt", '9ABC', @admin.merge!({:content_type => :text})
          assert_response :success # 201 - Created
      end

      Setting.plugin_redmine_dmsf['dmsf_webdav_disable_versioning'] = '.dump$'
      put "/dmsf/webdav/#{@project1.identifier}/file3.dump", '1234', @admin.merge!({:content_type => :text})
      assert_response :success
      file2 = DmsfFile.find_file_by_name @project1, nil, 'file3.dump'
      assert_difference 'file1.dmsf_file_revisions.count', 0 do
          put "/dmsf/webdav/#{@project1.identifier}/file3.dump", '5678', @admin.merge!({:content_type => :text})
          assert_response :success # 201 - Created
      end
      assert_difference 'file1.dmsf_file_revisions.count', 0 do
          put "/dmsf/webdav/#{@project1.identifier}/file3.dump", '9ABC', @admin.merge!({:content_type => :text})
          assert_response :success # 201 - Created
      end
    end
end
  
end