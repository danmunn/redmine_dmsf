# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFolderApiTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :projects, :users, :members, :roles,
           :member_roles

  def setup
    @dmsf_storage_directory = Setting.plugin_redmine_dmsf['dmsf_storage_directory']
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = 'files/dmsf'
    FileUtils.cp_r File.join(File.expand_path('../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    @admin = User.find 1
    @jsmith = User.find 2
    @file1 = DmsfFile.find 1
    @folder1 = DmsfFolder.find 1
    @folder7 = DmsfFolder.find 7
    Setting.rest_api_enabled = '1'
    @role = Role.find_by(name: 'Manager')
    @project1 = Project.find 1
    @project1.enable_module! :dmsf
  end

  def teardown
    # Delete our tmp folder
    begin
      FileUtils.rm_rf DmsfFile.storage_path
    rescue Exception => e
      error e.message
    end
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = @dmsf_storage_directory
  end

  def test_truth
    assert_kind_of User, @admin
    assert_kind_of User, @jsmith
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder7
    assert_kind_of DmsfFile, @file1
    assert_kind_of Role, @role
    assert_kind_of Project, @project1
  end

  def test_list_folder
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/17216.xml
    get "/projects/#{@project1.id}/dmsf.xml?key=#{token.value}"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    # <?xml version="1.0" encoding="UTF-8"?>
    #   <dmsf>
    #     <dmsf_folders total_count="3" type="array">
    #       <folder>
    #       <id>1</id>
    #         <title>folder1</title>
    #       </folder>
    #       <folder>
    #         <id>6</id>
    #       <title>folder6</title>
    #       </folder>
    #       <folder>
    #       <id>7</id>
    #         <title>folder7</title>
    #       </folder>
    #     </dmsf_folders>
    #     <dmsf_files total_count="4" type="array">
    #       <file>
    #       <id>9</id>
    #         <name>myfile.txt</name>
    #       </file>
    #       <file>
    #         <id>8</id>
    #       <name>test.pdf</name>
    #       </file>
    #       <file>
    #       <id>1</id>
    #         <name>test.txt</name>
    #       </file>
    #       <file>
    #         <id>10</id>
    #       <name>zero.txt</name>
    #       </file>
    #     </dmsf_files>
    #     <dmsf_links total_count="0" type="array">
    #     </dmsf_links>
    # </dmsf>
    assert_select 'dmsf > dmsf_folders > folder > id', :text => @folder1.id.to_s
    assert_select 'dmsf > dmsf_folders > folder > title', :text => @folder1.title.to_s
    assert_select 'dmsf > dmsf_files > file > id', :text => @file1.id.to_s
    assert_select 'dmsf > dmsf_files > file > name', :text => @file1.name.to_s
  end

  def test_list_folder_limit_and_offset
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} "http://localhost:3000/dmsf/files/17216.xml?limit=1&offset=1"
    get "/projects/#{@project1.id}/dmsf.xml?key=#{token.value}&limit=1&offset=2"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    #   <?xml version="1.0" encoding="UTF-8"?>
    #   <dmsf>
    #     <dmsf_folders total_count="1" type="array">
    #       <folder>
    #       <id>7</id>
    #         <title>folder7</title>
    #       </folder>
    #     </dmsf_folders>
    #     <dmsf_files total_count="1" type="array">
    #       <file>
    #       <id>1</id>
    #         <name>test.txt</name>
    #       </file>
    #     </dmsf_files>
    #     <dmsf_links total_count="0" type="array">
    #     </dmsf_links>
    # </dmsf>
    assert_select 'dmsf > dmsf_folders', :count => 1
    assert_select 'dmsf > dmsf_folders > folder > id', :text => @folder7.id.to_s
    assert_select 'dmsf > dmsf_folders > folder > title', :text => @folder7.title.to_s
    assert_select 'dmsf > dmsf_files', :count => 1
  end

  def test_create_folder
    @role.add_permission! :folder_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/xml" -X POST --data "@folder.xml" -u ${1}:${2} http://localhost:3000/projects/12/dmsf/create.xml
    payload = %{<?xml version="1.0" encoding="utf-8" ?>
                <dmsf_folder>
                  <title>rest_api</title>
                  <description>A folder created via REST API</description>
                  <dmsf_folder_id/>
                </dmsf_folder>}
    post "/projects/#{@project1.id}/dmsf/create.xml?key=#{token.value}", :params => payload, :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_folder>
    #   <id>8</id>
    #   <title>rest_api</title>
    # </dmsf_folder>
    assert_select 'dmsf_folder > title', :text => 'rest_api'
  end

  def test_find_folder_by_title
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000/projects/1/dmsf.json?folder_title=Updated%20title
    get "/projects/#{@project1.id}/dmsf.xml?key=#{token.value}&folder_title=#{@folder1.title}"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf>
    #   <dmsf_folders total_count="1" type="array">
    #     <folder>
    #       <id>2</id>
    #       <title>folder2</title>
    #     </folder>
    #   </dmsf_folders>
    #   <dmsf_files total_count="0" type="array">
    #   </dmsf_files>
    #   <dmsf_links total_count="0" type="array">
    #   </dmsf_links>
    #   <found_folder>
    #     <id>1</id>
    #     <title>folder1</title>
    #   </found_folder>
    # </dmsf>
    assert_select 'dmsf > found_folder > id', :text => @folder1.id.to_s
    assert_select 'dmsf > found_folder > title', :text => @folder1.title
  end

  def test_find_folder_by_title_not_found
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000/projects/1/dmsf.json?folder_title=Updated%20title
    get "/projects/#{@project1.id}/dmsf.xml?key=#{token.value}&folder_title=xxx"
    assert_response :not_found
  end

  def test_find_folder_by_id
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KE" http://localhost:3000/projects/1/dmsf.json?folder_id=3
    get "/projects/#{@project1.id}/dmsf.xml?key=#{token.value}&folder_id=#{@folder1.id}"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf>
    #   <dmsf_folders total_count="1" type="array">
    #     <folder>
    #       <id>2</id>
    #       <title>folder2</title>
    #     </folder>
    #   </dmsf_folders>
    #   <dmsf_files total_count="0" type="array">
    #   </dmsf_files>
    #   <dmsf_links total_count="0" type="array">
    #   </dmsf_links>
    #   <found_folder>
    #     <id>1</id>
    #     <title>folder1</title>
    #   </found_folder>
    # </dmsf>
    assert_select 'dmsf > found_folder > id', :text => @folder1.id.to_s
    assert_select 'dmsf > found_folder > title', :text => @folder1.title
  end

  def test_find_folder_by_id_not_found
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KE" http://localhost:3000/projects/1/dmsf.json?folder_id=3
    get "/projects/#{@project1.id}/dmsf.xml?key=#{token.value}&folder_id=99999999999"
    assert_response :not_found
  end

  def test_update_folder
    @role.add_permission! :folder_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/json" -X POST --data "@update-folder-payload.json" -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000//projects/#{project_id}/dmsf/save.json
    payload = %{<?xml version="1.0" encoding="utf-8" ?>
                <dmsf_folder>
                  <title>rest_api</title>
                  <description>A folder updated via REST API</description>
                </dmsf_folder>}
    post "/projects/#{@project1.id}/dmsf/save.xml?folder_id=1&key=#{token.value}", :params => payload, :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_folder>
    #   <id>1</id>
    #   <title>rest_api</title>
    #   <description>A folder updated via REST API</description>
    # </dmsf_folder>
    assert_select 'dmsf_folder > title', :text => 'rest_api'
  end

  def test_delete_folder
    @role.add_permission! :folder_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@project1.id}/dmsf/delete.xml?key=#{token.value}&folder_id=#{@folder1.id}",
         :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    @folder1.reload
    assert_equal DmsfFolder::STATUS_DELETED, @folder1.deleted
    assert_equal User.current, @folder1.deleted_by_user
  end

  def test_delete_folder_no_permission
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@project1.id}/dmsf/delete.xml?key=#{token.value}&folder_id=#{@folder1.id}",
           :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :forbidden
  end

  def test_delete_folder_commit_yes
    @role.add_permission! :folder_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@project1.id}/dmsf/delete.xml?key=#{token.value}&folder_id=#{@folder1.id}&commit=yes",
           :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    assert_nil DmsfFolder.find_by(id: @folder1.id)
  end

  def test_delete_folder_locked
    @role.add_permission! :folder_manipulation
    User.current = @admin
    @folder1.lock!
    User.current = @jsmith
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@project1.id}/dmsf/delete.xml?key=#{token.value}&folder_id=#{@folder1.id}",
         :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response 422
    # <?xml version="1.0" encoding="UTF-8"?>
    # <errors type="array">
    #   <error>Folder is locked</error>
    # </errors>
    assert_select 'errors > error', :text => l(:error_folder_is_locked)
    @folder1.reload
    assert_equal DmsfFolder::STATUS_ACTIVE, @folder1.deleted
  end

end