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

require File.expand_path('../../../test_helper', __FILE__)

class DmsfFolderApiTest < RedmineDmsf::Test::IntegrationTest

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :projects, :users, :members, :roles

  def setup
    DmsfFile.storage_path = File.expand_path '../../../../fixtures/files', __FILE__
    @jsmith = User.find_by_id 2
    @file1 = DmsfFile.find_by_id 1
    @folder1 = DmsfFolder.find_by_id 1
    Setting.rest_api_enabled = '1'
    @role = Role.find_by_id 1
  end

  def test_truth
    assert_kind_of User, @jsmith
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFile, @file1
    assert_kind_of Role, @role
  end

  def test_list_folder
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/17216.xml
    get "/projects/1/dmsf.xml?key=#{token.value}"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf>
    #   <dmsf_folders total_count="2" type="array">
    #     <folder>
    #       <id>1</id>
    #       <title>folder1</title>
    #     </folder>
    #     <folder>
    #       <id>6</id>
    #       <title>folder6</title>
    #     </folder>
    #   </dmsf_folders>
    #   <dmsf_files total_count="1" type="array">
    #     <file>
    #       <id>1</id>
    #       <name>test.txt</name>
    #     </file>
    #   </dmsf_files>
    #   <dmsf_links total_count="0" type="array">
    # </dmsf_links>
    # </dmsf>
    assert_select 'dmsf > dmsf_folders > folder > id', :text => @folder1.id.to_s
    assert_select 'dmsf > dmsf_folders > folder > title', :text => @folder1.title.to_s
    assert_select 'dmsf > dmsf_files > file > id', :text => @file1.id.to_s
    assert_select 'dmsf > dmsf_files > file > name', :text => @file1.name.to_s

  end

  def test_create_folder
    @role.add_permission! :folder_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/xml" -X POST --data "@folder.xml" -u ${1}:${2} http://localhost:3000/projects/12/dmsf/create.xml
    payload = %{
      <?xml version="1.0" encoding="utf-8" ?>
      <dmsf_folder>
        <title>rest_api</title>
        <description>A folder created via REST API</description>
        <dmsf_folder_id/>
      </dmsf_folder>
    }
    post "/projects/1/dmsf/create.xml?&key=#{token.value}", payload, {"CONTENT_TYPE" => 'application/xml'}
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
    get "/projects/1/dmsf.xml?key=#{token.value}&folder_title=#{@folder1.title}"
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
    get "/projects/1/dmsf.xml?key=#{token.value}&folder_title=xxx"
    assert_response :missing
  end

  def test_find_folder_by_id
    @role.add_permission! :view_dmsf_folders
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KE" http://localhost:3000/projects/1/dmsf.json?folder_id=3
    get "/projects/1/dmsf.xml?key=#{token.value}&folder_id=#{@folder1.id}"
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
    get "/projects/1/dmsf.xml?key=#{token.value}&folder_id=99999999999"
    assert_response :missing
  end

  def test_update_folder
    @role.add_permission! :folder_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    #curl -v -H "Content-Type: application/json" -X POST --data "@update-folder-payload.json" -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000//projects/#{project_id}/dmsf/save.json
    payload = %{
      <?xml version="1.0" encoding="utf-8" ?>
        <dmsf_folder>
          <title>rest_api</title>
          <description>A folder updated via REST API</description>
        </dmsf_folder>
    }
    post "/projects/1/dmsf/save.xml?folder_id=1&key=#{token.value}", payload, {"CONTENT_TYPE" => 'application/xml'}
    assert_response :success
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_folder>
    #   <id>1</id>
    #   <title>rest_api</title>
    #   <description>A folder updated via REST API</description>
    # </dmsf_folder>
    assert_select 'dmsf_folder > title', :text => 'rest_api'
  end

end