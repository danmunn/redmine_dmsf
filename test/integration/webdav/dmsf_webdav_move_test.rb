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

require File.expand_path('../../../test_helper', __FILE__)
require 'fileutils'

class DmsfWebdavMoveTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions
    
  def setup
    DmsfLock.delete_all # Delete all locks that are in our test DB - probably not safe but ho hum
    timestamp = DateTime.now.strftime('%y%m%d%H%M')
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.expand_path("./dmsf_test-#{timestamp}", DmsfHelper.temp_dir)
    Dir.mkdir(DmsfFile.storage_path) unless File.directory?(DmsfFile.storage_path)
    # Copy the physical files to the temporary storage
    files = File.expand_path('../../../fixtures/files', __FILE__) + '/.'
    FileUtils.cp_r files, DmsfFile.storage_path
    
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @file1 = DmsfFile.find_by_id 1
    @file10 = DmsfFile.find_by_id 10
    @folder1 = DmsfFolder.find_by_id 1

    # Fix permissions for jsmith's role
    @role = Role.find 1 #
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    
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
    assert_kind_of Role, @role
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file10
    assert_kind_of DmsfFolder, @folder1
  end

  def test_move_denied_for_anonymous
    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
        {:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"}
      assert_response 401
    end
  end

  def test_move_to_new_filename_without_folder_manipulation_permission
    @role.remove_permission! :folder_manipulation
    new_name = "#{@file1.name}.moved"
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      assert_no_difference '@file1.dmsf_file_revisions.count' do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
        assert_response 403
      end
    end
  end

  def test_move_to_new_filename_without_folder_manipulation_permission_as_admin
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      @role.remove_permission! :folder_manipulation
      new_name = "#{@file1.name}.moved"
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @admin.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
        assert_response 201 # Created
        f = DmsfFile.find_file_by_name @project1, nil, "#{new_name}"
        assert f, "Moved file '#{new_name}' not found in project."
      end
    end
  end

  def test_move_non_existent_file
    xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/not_a_file.txt", nil,
      @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/moved_file.txt"})
    assert_response 404 # NotFound
  end

  def test_move_wrong_destination
    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
        @jsmith.merge!({:destination => "http://www.wrong-url.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
      assert_response 502 # BadGateway
    end
  end

  def test_move_to_new_filename
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      new_name = "#{@file1.name}.moved"
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
        assert_response 201 # Created
        f = DmsfFile.find_file_by_name @project1, nil, "#{new_name}"
        assert f, "Moved file '#{new_name}' not found in project."
      end
    end
  end

  def test_move_to_new_filename_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
      project1_uri = Addressable::URI.escape(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      new_name = "#{@file1.name}.moved"
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{project1_uri}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{project1_uri}/#{new_name}"})
        assert_response 201 # Created
        f = DmsfFile.find_file_by_name @project1, nil, "#{new_name}"
        assert f, "Moved file '#{new_name}' not found in project."
      end
    end
  end

  def test_move_zero_sized_to_new_filename
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      new_name = "#{@file10.name}.moved"
      assert_no_difference '@file10.dmsf_file_revisions.count' do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file10.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
        assert_response 201 # Created
        f = DmsfFile.find_file_by_name @project1, nil, "#{new_name}"
        assert f, "Moved file '#{new_name}' not found in project."
      end
    end
  end

  def test_move_to_new_folder
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/#{@file1.name}"})
        assert_response 201 # Created
        @file1.reload
        assert_equal @folder1.id, @file1.dmsf_folder_id
      end
    end
  end

  def test_move_to_new_folder_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
      project1_uri = Addressable::URI.escape(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{project1_uri}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{project1_uri}/#{@folder1.title}/#{@file1.name}"})
        assert_response 201 # Created
        @file1.reload
        assert_equal @folder1.id, @file1.dmsf_folder_id
      end
    end
  end

  def test_move_zero_sized_to_new_folder
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      assert_no_difference '@file10.dmsf_file_revisions.count' do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file10.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/#{@file10.name}"})
        assert_response 201 # Created
        @file10.reload
        assert_equal @folder1.id, @file10.dmsf_folder_id
      end
    end
  end

  def test_move_to_existing_filename
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      file2 = DmsfFile.find_by_id 9
      new_name = "#{file2.name}"
      assert_no_difference 'file2.dmsf_file_revisions.count' do
        assert_no_difference '@file1.dmsf_file_revisions.count' do
          xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
            @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
          assert_response 405 # MethodNotAllowed
        end
      end
    end
  end

  def test_move_when_file_is_locked_by_other
    log_user 'admin', 'admin' # login as admin
    assert !User.current.anonymous?, 'Current user is anonymous'
    assert @file1.lock!, "File failed to be locked by #{User.current.name}"
    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
        @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
      assert_response 423 # Locked
    end
  end

  def test_move_when_file_is_locked_by_other_and_user_is_admin
    log_user 'jsmith', 'jsmith' # login as jsmith
    assert !User.current.anonymous?, 'Current user is anonymous'
    assert @file1.lock!, "File failed to be locked by #{User.current.name}"

    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
        @admin.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
      assert_response 423 # Locked
    end
  end

  def test_move_when_file_is_locked_by_user
    log_user 'jsmith', 'jsmith' # login as jsmith
    assert !User.current.anonymous?, 'Current user is anonymous'
    assert @file1.lock!, "File failed to be locked by #{User.current.name}"

    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      # Move once
      new_name = "#{@file1.name}.m1"
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}"})
        assert_response 201 # Created
      end
      # Move twice, make sure that the MsOffice store sequence is not disrupting normal move
      new_name2 = "#{new_name}.m2"
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{new_name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name2}"})
        assert_response 201 # Created
      end
    end
  end
  
  def test_move_msoffice_save_locked_file
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      # When some versions of MsOffice save a file they use the following sequence:
      # 1. Save changes to a new temporary document, XXX.tmp
      # 2. Rename (MOVE) document to YYY.tmp. History is lost here if the original document is moved.
      # 3. Rename (MOVE) XXX.tmp to document's name. XXX.tmp must be merged to the original document otherwise the history is lost.
      # 4. Delete YYY.tmp.
      # Verify that steps 2 and 3 work.
      log_user 'jsmith', 'jsmith' # login as jsmith
      assert !User.current.anonymous?, 'Current user is anonymous'
      assert @file1.lock!, "File failed to be locked by #{User.current.name}"

      # First save while the file is locked, should create new revision
      temp_file_name = 'AAAAAAAA.tmp'

      # Make sure that the temp-file does not exist.
      temp_file = DmsfFile.find_file_by_name @project1, nil, "#{temp_file_name}"
      assert !temp_file, "File '#{temp_file_name}' should not exist yet."

      # Move the original file to AAAAAAAA.tmp. The original file should not changed but a new file should be created.
      assert_no_difference '@file1.dmsf_file_revisions.count' do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}"})
        assert_response 201 # Created
      end

      # Verify that a new file has been created
      temp_file = DmsfFile.find_file_by_name @project1, nil, "#{temp_file_name}"
      assert temp_file, "File '#{temp_file_name}' not found, move failed."
      assert_equal temp_file.dmsf_file_revisions.count,1
      assert_not_equal temp_file.id, @file1.id

      # Move a temporary file (use AAAAAAAA.tmp) to the original file.
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@file1.name}"})
        assert_response 201 # Created
      end

      # Second save while file is locked, should NOT create new revision
      temp_file_name = 'BBBBBBBB.tmp'

      # Make sure that the temp-file does not exist.
      temp_file = DmsfFile.find_file_by_name @project1, nil, "#{temp_file_name}"
      assert !temp_file, "File '#{temp_file_name}' should not exist yet."

      # Move the original file to BBBBBBBB.tmp. The original file should not change but a new file should be created.
      assert_no_difference '@file1.dmsf_file_revisions.count' do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}"})
        assert_response 201 # Created
      end

      # Verify that a new file has been created
      temp_file = DmsfFile.find_file_by_name @project1, nil, "#{temp_file_name}"
      assert temp_file, "File '#{temp_file_name}' not found, move failed."
      assert_equal temp_file.dmsf_file_revisions.count,1
      assert_not_equal temp_file.id, @file1.id

      # Move a temporary file (use BBBBBBBB.tmp) to the original file.
      assert_no_difference '@file1.dmsf_file_revisions.count' do
        xml_http_request :move, "/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}", nil,
          @jsmith.merge!({:destination => "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@file1.name}"})
        assert_response 201 # Created
      end
    end
  end
  
end