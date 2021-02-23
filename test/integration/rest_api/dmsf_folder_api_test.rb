# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def setup
    super
    Setting.rest_api_enabled = '1'
    @token = Token.create!(user: @jsmith_user, action: 'api')
  end

  def test_list_folder
    #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/17216.xml
    get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf>
    #   <dmsf_nodes total_count="7" type="array">
    #     <node>
    #       <id>1</id>
    #       <title>folder1</title>
    #       <type>folder</type>
    #     </node>
    #     ...
    #   </dmsf_nodes>
    # </dmsf>
    assert_select 'dmsf > dmsf_nodes > node > id', text: @folder1.id.to_s
    assert_select 'dmsf > dmsf_nodes > node > title', text: @folder1.title
    assert_select 'dmsf > dmsf_nodes > node > type', text: 'folder'
  end

  def test_list_folder_with_sub_projects
    with_settings plugin_redmine_dmsf: {'dmsf_projects_as_subfolders' => '1'} do
      #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/17216.xml
      get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}"
      assert_response :success
      assert_equal 'application/xml', @response.content_type
      # <?xml version="1.0" encoding="UTF-8"?>
      # <dmsf>
      #   <dmsf_nodes total_count="9" type="array">
      #     <node>
      #       <id>3</id>
      #       <title>eCookbook Subproject 1</title>
      #       <type>project</type>
      #     </node>
      #     ...
      #   </dmsf_nodes>
      # </dmsf>
      # @project3 is as a sub-folder
      assert_select 'dmsf > dmsf_nodes > node > id', text: @project3.id.to_s
      assert_select 'dmsf > dmsf_nodes > node > title', text: @project3.name
      assert_select 'dmsf > dmsf_nodes > node > type', text: 'project'
    end
  end

  def test_list_folder_limit_and_offset
    #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} "http://localhost:3000/dmsf/files/17216.xml?limit=1&offset=1"
    get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}&limit=1&offset=2"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    #   <?xml version="1.0" encoding="UTF-8"?>
    #   <dmsf>
    #     <dmsf_nodes total_count="1" type="array">
    #       <node>
    #         <id>7</id>
    #         <title>folder7</title>
    #         <type>folder</type>
    #         <filename/>
    #       </node>
    #     </dmsf_nodes>
    # </dmsf>
    assert_select 'dmsf > dmsf_nodes > node', count: 1
    assert_select 'dmsf > dmsf_nodes > node > id', text: @folder7.id.to_s
    assert_select 'dmsf > dmsf_nodes > node > title', text: @folder7.title
  end

  def test_create_folder
    #curl -v -H "Content-Type: application/xml" -X POST --data "@folder.xml" -u ${1}:${2} http://localhost:3000/projects/12/dmsf/create.xml
    payload = %{<?xml version="1.0" encoding="utf-8" ?>
                <dmsf_folder>
                  <title>rest_api</title>
                  <description>A folder created via REST API</description>
                  <dmsf_folder_id/>
                </dmsf_folder>}
    post "/projects/#{@project1.identifier}/dmsf/create.xml?key=#{@token.value}", params: payload, headers: { 'CONTENT_TYPE' => 'application/xml' }
    assert_response :success
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_folder>
    #   <id>8</id>
    #   <title>rest_api</title>
    # </dmsf_folder>
    assert_select 'dmsf_folder > title', text: 'rest_api'
  end

  def test_find_folder_by_title
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000/projects/1/dmsf.json?folder_title=Updated%20title
    get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}&folder_title=#{@folder1.title}"
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
    assert_select 'dmsf > found_folder > id', text: @folder1.id.to_s
    assert_select 'dmsf > found_folder > title', text: @folder1.title
  end

  def test_find_folder_by_title_not_found
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000/projects/1/dmsf.json?folder_title=Updated%20title
    get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}&folder_title=xxx"
    assert_response :not_found
  end

  def test_find_folder_by_id
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KE" http://localhost:3000/projects/1/dmsf.json?folder_id=3
    get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}&folder_id=#{@folder1.id}"
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
    assert_select 'dmsf > found_folder > id', text: @folder1.id.to_s
    assert_select 'dmsf > found_folder > title', text: @folder1.title
  end

  def test_find_folder_by_id_not_found
    # curl -v -H "Content-Type: application/json" -X GET -H "X-Redmine-API-Key: USERS_API_KE" http://localhost:3000/projects/1/dmsf.json?folder_id=3
    get "/projects/#{@project1.identifier}/dmsf.xml?key=#{@token.value}&folder_id=none"
    assert_response :not_found
  end

  def test_update_folder
    #curl -v -H "Content-Type: application/json" -X POST --data "@update-folder-payload.json" -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000//projects/#{project_id}/dmsf/save.json
    payload = %{<?xml version="1.0" encoding="utf-8" ?>
                <dmsf_folder>
                  <title>rest_api</title>
                  <description>A folder updated via REST API</description>
                </dmsf_folder>}
    post "/projects/#{@project1.identifier}/dmsf/save.xml?folder_id=1&key=#{@token.value}", params: payload, headers: { 'CONTENT_TYPE' => 'application/xml' }
    assert_response :success
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_folder>
    #   <id>1</id>
    #   <title>rest_api</title>
    #   <description>A folder updated via REST API</description>
    # </dmsf_folder>
    assert_select 'dmsf_folder > title', text: 'rest_api'
  end

  def test_delete_folder
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@folder6.project.identifier}/dmsf/delete.xml?key=#{@token.value}&folder_id=#{@folder6.id}",
         headers: { 'CONTENT_TYPE' => 'application/xml' }
    assert_response :success
    @folder6.reload
    assert_equal DmsfFolder::STATUS_DELETED, @folder6.deleted
    assert_equal @jsmith_user, @folder6.deleted_by_user
  end

  def test_delete_folder_no_permission
    @role.remove_permission! :folder_manipulation
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@folder6.project.identifier}/dmsf/delete.xml?key=#{@token.value}&folder_id=#{@folder6.id}",
           headers: {'CONTENT_TYPE' => 'application/xml'}
    assert_response :forbidden
  end

  def test_delete_folder_commit_yes
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@folder6.project.identifier}/dmsf/delete.xml?key=#{@token.value}&folder_id=#{@folder6.id}&commit=yes",
           headers: { CONTENT_TYPE: 'application/xml' }
    assert_response :success
    assert_nil DmsfFolder.find_by(id: @folder6.id)
  end

  def test_delete_folder_locked
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/projects/1/dmsf/delete.xml?folder_id=3
    delete "/projects/#{@folder2.project.identifier}/dmsf/delete.xml?key=#{@token.value}&folder_id=#{@folder2.id}",
         headers: { 'CONTENT_TYPE' => 'application/xml' }
    assert_response 422
    # <?xml version="1.0" encoding="UTF-8"?>
    # <errors type="array">
    #   <error>Folder is locked</error>
    # </errors>
    assert_select 'errors > error', text: l(:error_folder_is_locked)
    @folder2.reload
    assert_equal DmsfFolder::STATUS_ACTIVE, @folder2.deleted
  end

end