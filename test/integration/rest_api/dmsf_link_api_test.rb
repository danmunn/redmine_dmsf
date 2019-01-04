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

class DmsfLinkApiTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n

  fixtures :projects, :users, :dmsf_files, :dmsf_file_revisions, :members, :roles, :member_roles

  def setup
    @admin = User.find 1
    @jsmith = User.find 2
    @file1 = DmsfFile.find 1
    Setting.rest_api_enabled = '1'
    @role = Role.find 1
    @project1 = Project.find 1
    @project1.enable_module! :dmsf
  end

  def test_truth
    assert_kind_of User, @admin
    assert_kind_of User, @jsmith
    assert_kind_of DmsfFile, @file1
    assert_kind_of Role, @role
    assert_kind_of Project, @project1
  end

  def test_create_link
    @role.add_permission! :file_manipulation
    token = Token.create!(:user => @jsmith, :action => 'api')
    name = 'REST API link test'
    # curl -v -H "Content-Type: application/xml" -X POST --data "@link.xml" -H "X-Redmine-API-Key: USERS_API_KEY" http://localhost:3000/dmsf_links.xml
    payload = %{<?xml version="1.0" encoding="utf-8" ?>
                <dmsf_link>
                  <project_id>#{@project1.id}</project_id>
                  <type>link_from</type>
                  <dmsf_file_id></dmsf_file_id>
                  <target_project_id>#{@project1.id}</target_project_id>
                  <target_folder_id>Documents</target_folder_id>
                  <target_file_id>#{@file1.id}</target_file_id>
                  <external_url></external_url>
                  <name>#{name}</name>
                </dmsf_link>}
    post "/dmsf_links.xml?key=#{token.value}", :params => payload, :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_link>
    #   <id>1243</id>
    #   <title>test</title>
    # </dmsf_link>
    assert_select 'dmsf_link > title', :text => name
    assert_equal 1, DmsfLink.where(:name => name, :project_id => @project1.id).count
  end
end