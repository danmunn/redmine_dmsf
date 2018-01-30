# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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
require 'uri'

class DmsfWebdavPropfindTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith' # Not a member of project1
    @project1 = Project.find_by_id 1 # DMSF enabled
    @project2 = Project.find_by_id 2 # DMSF disabled
    # Folders in project1
    @folder1 = DmsfFolder.find_by_id 1
    @folder6 = DmsfFolder.find_by_id 6
    # Files in project1
    @file1 = DmsfFile.find_by_id 1
    @file9 = DmsfFile.find_by_id 9
    @file10 = DmsfFile.find_by_id 10
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    # Temporarily enable project names to generate names for project1
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    @project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
    @project1_uri = Addressable::URI.escape(@project1_name)
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = false
    Setting.plugin_redmine_dmsf['dmsf_webdav_caching_enabled'] = '1'
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end

  def test_propfind_denied_for_anonymous
    xml_http_request :propfind, '/dmsf/webdav/', nil, {:HTTP_DEPTH => '0'}
    assert_response 401
  end

  def test_propfind_depth0_on_root_for_non_member
    xml_http_request :propfind, '/dmsf/webdav/', nil, @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_non_member
    xml_http_request :propfind, '/dmsf/webdav/', nil, @jsmith.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?( '<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth0_on_root_for_admin
    xml_http_request :propfind, '/dmsf/webdav/', nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_admin
    xml_http_request :propfind, '/dmsf/webdav/', nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    xml_http_request :propfind, '/dmsf/webdav/', nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
    # project.identifier should not match when using project names
    assert !response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    assert !response.body.include?("<d:displayname>#{@project1.identifier}</d:displayname>")
    # but the project name should match
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</d:href>")
    assert response.body.include?("<d:displayname>#{@project1_name}</d:displayname>")
  end

  def test_propfind_depth0_on_project1_for_non_member
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response :missing
  end

  def test_propfind_depth0_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    assert response.body.include?("<d:displayname>#{@project1.identifier}</d:displayname>")
  end

  def test_propfind_depth0_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response :missing
    xml_http_request :propfind, "/dmsf/webdav/#{@project1_uri}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</d:href>")
    assert response.body.include?("<d:displayname>#{@project1_name}</d:displayname>")
  end

  def test_propfind_depth1_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    assert response.body.include?("<d:displayname>#{@project1.identifier}</d:displayname>")
    # Folders
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</d:href>")
    assert response.body.include?("<d:displayname>#{@folder1.title}</d:displayname>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</d:href>")
    assert response.body.include?("<d:displayname>#{@folder6.title}</d:displayname>")
    # Files
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</d:href>")
    assert response.body.include?("<d:displayname>#{@file1.name}</d:displayname>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</d:href>")
    assert response.body.include?("<d:displayname>#{@file9.name}</d:displayname>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</d:href>")
    assert response.body.include?("<d:displayname>#{@file10.name}</d:displayname>")
  end

  def test_propfind_depth1_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :missing
    xml_http_request :propfind, "/dmsf/webdav/#{@project1_uri}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</d:href>")
    # Folders
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@folder1.title}/</d:href>")
    assert response.body.include?("<d:displayname>#{@folder1.title}</d:displayname>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@folder6.title}/</d:href>")
    assert response.body.include?("<d:displayname>#{@folder6.title}</d:displayname>")
    # Files
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file1.name}</d:href>")
    assert response.body.include?("<d:displayname>#{@file1.name}</d:displayname>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file9.name}</d:href>")
    assert response.body.include?("<d:displayname>#{@file9.name}</d:displayname>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file10.name}</d:href>")
    assert response.body.include?("<d:displayname>#{@file10.name}</d:displayname>")
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names
    @project1.name = 'Online Cookbook'
    @project1.save!
    project1_new_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
    project1_new_uri = Addressable::URI.escape(project1_new_name)
    xml_http_request :propfind, "/dmsf/webdav/#{project1_new_uri}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{project1_new_uri}/</d:href>")
    assert response.body.include?("<d:displayname>#{project1_new_name}</d:displayname>")
  end

  def test_propfind_depth0_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
  end

  def test_propfind_depth1_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    # Folders
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</d:href>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</d:href>")
    # Files
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</d:href>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</d:href>")
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</d:href>")
  end

  def test_propfind_depth1_on_project1_for_admin
    log_user 'admin', 'admin' # login as admin
    assert !User.current.anonymous?, 'Current user is anonymous'
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
  end

end