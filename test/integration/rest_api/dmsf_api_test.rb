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
    assert_equal 'application/xml', @response.content_type
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
end