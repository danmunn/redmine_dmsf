# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# DMSF API
class DmsfFileApiTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks, :dmsf_links

  def setup
    super
    Setting.rest_api_enabled = '1'
    @token = Token.create!(user: @jsmith_user, action: 'api')
  end

  def test_get
    # curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/projects/12/dmsf.xml
    get "/projects/#{@project1.id}/dmsf.xml?key=#{@token.value}"
    assert_response :success
    assert @response.media_type.include?('application/xml')
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf>
    #   <dmsf_nodes total_count="10" type="array">
    #     <node>
    #       <id>1</id>
    #       <title>folder1</title>
    #       <type>folder</type>
    #     </node>
    #     <node>
    #       <id>1</id>
    #       <title>folder1_link</title>
    #       <type>folder-link</type>
    #       <target_id>1</target_id>
    #       <target_project_id>1</target_project_id>
    #     </node>
    #     <node>
    #       <id>6</id>
    #       <title>folder6</title>
    #       <type>folder</type>
    #     </node>
    #     <node>
    #       <id>7</id>
    #       <title>folder7</title>
    #       <type>folder</type>
    #     </node>
    #     <node>
    #       <id>6</id>
    #       <title>file1_link</title>
    #       <type>file-link</type>
    #       <target_id>1</target_id>
    #       <target_project_id>1</target_project_id>
    #     </node>
    #     <node>
    #       <id>9</id>
    #       <title>My File</title>
    #       <type>file</type>
    #       <filename>myfile.txt</filename>
    #     </node>
    #     <node>
    #       <id>8</id>
    #       <title>PDF</title>
    #       <type>file</type>
    #       <filename>test.pdf</filename>
    #     </node>
    #     <node>
    #       <id>1</id>
    #       <title>Test File</title>
    #       <type>file</type>
    #       <filename>test5.txt</filename>
    #     </node>
    #     <node>
    #       <id>4</id>
    #       <title>test_link</title>
    #       <type>file-link</type>
    #       <target_id>4</target_id>
    #       <target_project_id>1</target_project_id>
    #     </node>
    #     <node>
    #       <id>10</id>
    #       <title>Zero Size File</title>
    #       <type>file</type>
    #       <filename>zero.txt</filename>
    #     </node>
    #   </dmsf_nodes>
    # </dmsf>
    assert_select 'node > id', text: @folder1.id.to_s
    assert_select 'node > title', text: @folder1.title
    assert_select 'node > type', text: 'folder'
    assert_select 'node > filename', text: @file9.last_revision.name
    assert_select 'node > target_id', text: @folder_link1.target_id.to_s
    assert_select 'node > target_project_id', text: @folder_link1.target_project_id.to_s
  end

  def test_copy_entries
    # curl -v -H "Content-Type: application/xml" -X POST --data "@entries.xml" -H "X-Redmine-API-Key: ${USER_API_KEY}" \
    # "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566&copy_entries=true"
    payload = %(
      <?xml version="1.0" encoding="utf-8" ?>
      <dmsf_entries>
        <target_project_id>#{@project1.id}</target_project_id>
        <target_folder_id>#{@folder1.id}</target_folder_id>
      </dmsf_entries>
    )
    assert_difference('@folder1.dmsf_files.count', 1) do
      post "/projects/#{@project1.id}/dmsf/entries.xml?ids[]=file-#{@file1.id}&copy_entries=true&key=#{@token.value}",
           params: payload,
           headers: { 'CONTENT_TYPE' => 'application/xml' }
    end
    assert_response :redirect
  end

  def test_move_entries
    # curl -v -H "Content-Type: application/xml" -X POST --data "@entries.xml" -H "X-Redmine-API-Key: ${USER_API_KEY}" \
    # "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566&move_entries=true"
    payload = %(
      <?xml version="1.0" encoding="utf-8" ?>
      <dmsf_entries>
        <target_project_id>#{@project1.id}</target_project_id>
        <target_folder_id>#{@folder1.id}</target_folder_id>
      </dmsf_entries>
    )
    assert_difference('@folder1.dmsf_files.count', 1) do
      post "/projects/#{@project1.id}/dmsf/entries.xml?ids[]=file-#{@file1.id}&move_entries=true&key=#{@token.value}",
           params: payload,
           headers: { 'CONTENT_TYPE' => 'application/xml' }
    end
    assert_response :redirect
  end

  def test_download_entries
    # curl -v -H "Content-Type: application/xml" -X POST --data "" -H "X-Redmine-API-Key: ${USER_API_KEY}" \
    # "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566"
    post "/projects/#{@project1.id}/dmsf/entries.xml?ids[]=file-#{@file1.id}&key=#{@token.value}",
         params: '',
         headers: { 'CONTENT_TYPE' => 'application/octet-stream' }
    assert_response :success
  end

  def test_delete_entries
    # curl -v -H "Content-Type: application/xml" -X POST --data "" -H "X-Redmine-API-Key: ${USER_API_KEY}" \
    # "http://localhost:3000/projects/3342/dmsf/entries.xml?ids[]=file-254566&delete_entries=true"
    assert_difference('@project1.dmsf_files.visible.count', -1) do
      post "/projects/#{@project1.id}/dmsf/entries.xml?ids[]=file-#{@file1.id}&delete_entries=true&key=#{@token.value}",
           params: '',
           headers: { 'CONTENT_TYPE' => 'application/xml' }
    end
    assert_response :redirect
  end
end
