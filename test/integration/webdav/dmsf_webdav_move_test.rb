# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

# WebDAV MOVE tests
class DmsfWebdavMoveTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_move_denied_for_anonymous
    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
      assert_response :unauthorized
    end
  end

  def test_move_to_new_filename_without_file_manipulation_permission
    @role.remove_permission! :file_manipulation
    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :forbidden
    end
  end

  def test_move_to_new_filename_without_file_manipulation_permission_as_admin
    @role.remove_permission! :file_manipulation
    new_name = "#{@file1.name}.moved"
    assert_difference '@file1.dmsf_file_revisions.count', +1 do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @admin.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :created
      f = DmsfFile.find_file_by_name @project1, nil, new_name
      assert f, "Moved file '#{new_name}' not found in project."
    end
  end

  def test_without_folder_manipulation_permission
    @role.remove_permission! :folder_manipulation
    new_name = "#{@folder1.title}.moved"
    process :move,
            "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}",
            params: nil,
            headers: @jsmith.merge!(
              { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
            )
    assert_response :forbidden
  end

  def test_without_folder_manipulation_permission_as_admin
    @role.remove_permission! :folder_manipulation
    new_name = "#{@folder1.title}.moved"
    process :move,
            "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}",
            params: nil,
            headers: @admin.merge!(
              { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
            )
    assert_response :created
  end

  def test_move_folder_to_another_project
    process :move,
            "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}",
            params: nil,
            headers: @admin.merge!(
              { destination: "http://www.example.com/dmsf/webdav/#{@project2.identifier}/#{@folder1.title}" }
            )
    assert_response :created
    @folder1.dmsf_folders.each do |d|
      assert_equal @project2, d.project
    end
    @folder1.dmsf_files.each do |f|
      assert_equal @project2, f.project
    end
    @folder1.dmsf_links.each do |l|
      assert_equal @project2, l.project
    end
  end

  def test_move_non_existent_file
    process :move,
            "/dmsf/webdav/#{@project1.identifier}/not_a_file.txt",
            params: nil,
            headers: @jsmith.merge!(
              { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/moved_file.txt" }
            )
    assert_response :not_found # NotFound
  end

  def test_move_to_new_filename
    new_name = "#{@file1.name}.moved"
    assert_difference '@file1.dmsf_file_revisions.count', +1 do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :created
      f = DmsfFile.find_file_by_name @project1, nil, new_name
      assert f, "Moved file '#{new_name}' not found in project."
    end
  end

  def test_move_to_new_filename_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      project1_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      new_name = "#{@file1.name}.moved"
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        process :move, "/dmsf/webdav/#{project1_uri}/#{@file1.name}",
                params: nil,
                headers: @jsmith.merge!(
                  { destination: "http://www.example.com/dmsf/webdav/#{project1_uri}/#{new_name}" }
                )
        assert_response :created
        f = DmsfFile.find_file_by_name @project1, nil, new_name
        assert f, "Moved file '#{new_name}' not found in project."
      end
    end
  end

  def test_move_zero_sized_to_new_filename
    new_name = "#{@file10.name}.moved"
    assert_no_difference '@file10.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file10.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :created
      f = DmsfFile.find_file_by_name @project1, nil, new_name
      assert f, "Moved file '#{new_name}' not found in project."
    end
  end

  def test_move_to_new_folder
    assert_difference '@file1.dmsf_file_revisions.count', +1 do
      process(
        :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
        params: nil,
        headers: @jsmith.merge!(
          { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/#{@file1.name}" }
        )
      )
      assert_response :created
      @file1.reload
      assert_equal @folder1.id, @file1.dmsf_folder_id
    end
  end

  def test_move_to_new_folder_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      project1_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
      assert_difference '@file1.dmsf_file_revisions.count', +1 do
        process :move,
                "/dmsf/webdav/#{project1_uri}/#{@file1.name}",
                params: nil,
                headers: @jsmith.merge!(
                  { destination: "http://www.example.com/dmsf/webdav/#{project1_uri}/#{@folder1.title}/#{@file1.name}" }
                )
        assert_response :created
        @file1.reload
        assert_equal @folder1.id, @file1.dmsf_folder_id
      end
    end
  end

  def test_move_zero_sized_to_new_folder
    assert_no_difference '@file10.dmsf_file_revisions.count' do
      process(
        :move, "/dmsf/webdav/#{@project1.identifier}/#{@file10.name}",
        params: nil,
        headers: @jsmith.merge!(
          { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/#{@file10.name}" }
        )
      )
      assert_response :created
      @file10.reload
      assert_equal @folder1.id, @file10.dmsf_folder_id
    end
  end

  def test_move_to_existing_filename
    assert_no_difference '@file9.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@file9.name}" }
              )
      assert_response 412
    end
  end

  def test_move_when_file_is_locked_by_other
    log_user 'admin', 'admin' # login as admin
    User.current = @admin_user
    assert @file1.lock!, "File failed to be locked by #{User.current}"
    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :locked
    end
  end

  def test_move_when_file_is_locked_by_other_and_user_is_admin
    log_user 'jsmith', 'jsmith' # login as jsmith
    User.current = @jsmith_user
    assert @file1.lock!, "File failed to be locked by #{User.current}"

    new_name = "#{@file1.name}.moved"
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @admin.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :locked
    end
  end

  def test_move_when_file_is_locked_by_user
    log_user 'jsmith', 'jsmith' # login as jsmith
    User.current = @jsmith_user
    assert @file1.lock!, "File failed to be locked by #{User.current}"

    # Move once
    new_name = "#{@file1.name}.m1"
    assert_difference '@file1.dmsf_file_revisions.count', +1 do
      process :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name}" }
              )
      assert_response :success # Created
    end
    # Move twice, make sure that the MsOffice store sequence is not disrupting normal move
    new_name2 = "#{new_name}.m2"
    assert_difference '@file1.dmsf_file_revisions.count', +1 do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{new_name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{new_name2}" }
              )
      assert_response :success # Created
    end
  end

  def test_move_msoffice_save_locked_file
    # When some versions of MsOffice save a file they use the following sequence:
    # 1. Save changes to a new temporary document, XXX.tmp
    # 2. Rename (MOVE) document to YYY.tmp. History is lost here if the original document is moved.
    # 3. Rename (MOVE) XXX.tmp to document's name. XXX.tmp must be merged to the original document otherwise the
    # history is lost.
    # 4. Delete YYY.tmp.
    # Verify that steps 2 and 3 work.
    log_user 'jsmith', 'jsmith' # login as jsmith
    User.current = @jsmith_user
    assert @file1.lock!, "File failed to be locked by #{User.current}"

    # First save while the file is locked, should create new revision
    temp_file_name = 'AAAAAAAA.tmp'

    # Make sure that the temp-file does not exist.
    temp_file = DmsfFile.find_file_by_name @project1, nil, temp_file_name
    assert_not temp_file, "File '#{temp_file_name}' should not exist yet."

    # Move the original file to AAAAAAAA.tmp. The original file should not changed but a new file should be created.
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}" }
              )
      assert_response :success # Created
    end

    # Verify that a new file has been created
    temp_file = DmsfFile.find_file_by_name @project1, nil, temp_file_name
    assert temp_file, "File '#{temp_file_name}' not found, move failed."
    assert_equal temp_file.dmsf_file_revisions.count, 1
    assert_not_equal temp_file.id, @file1.id

    # Move a temporary file (use AAAAAAAA.tmp) to the original file.
    assert_difference '@file1.dmsf_file_revisions.count', +1 do
      process :move,
              "/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}",
              params: nil,
              headers: @jsmith.merge!(
                {
                  destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
                  'HTTP_OVERWRITE' => 'T'
                }
              )
      assert_response :success # Created
    end

    # Second save while file is locked, should NOT create new revision
    temp_file_name = 'BBBBBBBB.tmp'

    # Make sure that the temp-file does not exist.
    temp_file = DmsfFile.find_file_by_name @project1, nil, temp_file_name
    assert_not temp_file, "File '#{temp_file_name}' should not exist yet."

    # Move the original file to BBBBBBBB.tmp. The original file should not change but a new file should be created.
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}" }
              )
      assert_response :success # Created
    end

    # Verify that a new file has been created
    temp_file = DmsfFile.find_file_by_name @project1, nil, temp_file_name
    assert temp_file, "File '#{temp_file_name}' not found, move failed."
    assert_equal temp_file.dmsf_file_revisions.count, 1
    assert_not_equal temp_file.id, @file1.id

    # Move a temporary file (use BBBBBBBB.tmp) to the original file.
    assert_no_difference '@file1.dmsf_file_revisions.count' do
      process :move, "/dmsf/webdav/#{@project1.identifier}/#{temp_file_name}",
              params: nil,
              headers: @jsmith.merge!(
                { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@file1.name}" }
              )
      assert_response :success # Created
    end
  end

  def test_move_file_in_subproject
    dest = "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/new_file_name"
    assert_difference '@file12.dmsf_file_revisions.count', +1 do
      process :move, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@file12.name}",
              params: nil,
              headers: @admin.merge!({ destination: dest })
      assert_response :created
    end
  end

  def test_move_folder_in_subproject
    dest = "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/new_folder_name"
    process :move,
            "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@folder10.title}",
            params: nil,
            headers: @admin.merge!({ destination: dest })
    assert_response :created
    @folder10.reload
    assert_equal 'new_folder_name', @folder10.title
  end

  def test_move_folder_in_subproject_to_the_same_name_as_subproject
    dest = "http://www.example.com/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@project5.identifier}"
    process :move,
            "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/#{@folder10.title}",
            params: nil,
            headers: @admin.merge!({ destination: dest })
    assert_response :created
    @folder10.reload
    assert_equal @project5.identifier, @folder10.title
  end

  def test_move_subproject
    process :move, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}",
            params: nil,
            headers: @admin.merge!(
              { destination: "http://www.example.com/dmsf/webdav/#{@project1.identifier}/new_project_name" }
            )
    assert_response :method_not_allowed
  end
end
