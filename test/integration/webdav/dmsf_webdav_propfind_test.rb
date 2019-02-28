# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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
require 'uri'

class DmsfWebdavPropfindTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith' # Not a member of project1
    @project1 = Project.find 1 # DMSF enabled
    @project2 = Project.find 2 # DMSF disabled
    # Folders in project1
    @folder1 = DmsfFolder.find 1
    @folder6 = DmsfFolder.find 6
    # Files in project1
    @file1 = DmsfFile.find 1
    @file9 = DmsfFile.find 9
    @file10 = DmsfFile.find 10
    @dmsf_webdav = Setting.plugin_redmine_dmsf['dmsf_webdav']
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = true
    @dmsf_webdav_strategy = Setting.plugin_redmine_dmsf['dmsf_webdav_strategy']
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    # Temporarily enable project names to generate names for project1
    @dmsf_webdav_use_project_names = Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    @project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
    @project1_uri = Addressable::URI.escape(@project1_name)
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = false
  end

  def teardown
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = @dmsf_webdav
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = @dmsf_webdav_strategy
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = @dmsf_webdav_use_project_names
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end

  def test_propfind_denied_for_anonymous
    process :propfind, '/dmsf/webdav/', :params => nil, :headers => {:HTTP_DEPTH => '0'}
    assert_response :unauthorized
  end

  def test_propfind_depth0_on_root_for_non_member
    process :propfind, '/dmsf/webdav/', :params => nil, :headers => @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response :multi_status
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_non_member
    process :propfind, '/dmsf/webdav/', :params => nil, :headers => @jsmith.merge!({:HTTP_DEPTH => '1'})
    assert_response :multi_status
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?( '<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth0_on_root_for_admin
    process :propfind, '/dmsf/webdav/', :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response :multi_status
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    process :propfind, '/dmsf/webdav/', :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :multi_status
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
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", :params => nil, :headers => @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response :not_found
  end

  def test_propfind_depth0_on_project1_for_admin
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response :multi_status
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    assert response.body.include?("<d:displayname>#{@project1.identifier}</d:displayname>")
  end

  def test_propfind_depth0_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response :not_found
    process :propfind, "/dmsf/webdav/#{@project1_uri}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response :multi_status
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</d:href>")
    assert response.body.include?("<d:displayname>#{@project1_name}</d:displayname>")
  end

  def test_propfind_depth1_on_project1_for_admin
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :multi_status
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
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :not_found
    process :propfind, "/dmsf/webdav/#{@project1_uri}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :multi_status
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

  def test_propfind_depth1_on_root_for_admin
    @project1.name = 'Online Cookbook'
    @project1.save!
    project1_new_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
    project1_new_uri = Addressable::URI.escape(project1_new_name)
    process :propfind, "/dmsf/webdav/#{project1_new_uri}", :params => nil, :headers => @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :multi_status
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{project1_new_uri}/</d:href>")
    assert response.body.include?("<d:displayname>#{project1_new_name}</d:displayname>")
  end

end