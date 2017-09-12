# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
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
    RedmineDmsf::Webdav::Cache.clear
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
    assert response.body.include?('<D:href>http://www.example.com:80/dmsf/webdav/</D:href>')
    assert response.body.include?('<D:displayname>/</D:displayname>')
  end

  def test_propfind_depth1_on_root_for_non_member
    xml_http_request :propfind, '/dmsf/webdav/', nil, @jsmith.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<D:href>http://www.example.com:80/dmsf/webdav/</D:href>')
    assert response.body.include?( '<D:displayname>/</D:displayname>')
  end

  def test_propfind_depth0_on_root_for_admin
    xml_http_request :propfind, '/dmsf/webdav/', nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<D:href>http://www.example.com:80/dmsf/webdav/</D:href>')
    assert response.body.include?('<D:displayname>/</D:displayname>')
  end

  def test_propfind_depth1_on_root_for_admin
    xml_http_request :propfind, '/dmsf/webdav/', nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<D:href>http://www.example.com:80/dmsf/webdav/</D:href>')
    assert response.body.include?('<D:displayname>/</D:displayname>')
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    xml_http_request :propfind, '/dmsf/webdav/', nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?('<D:href>http://www.example.com:80/dmsf/webdav/</D:href>')
    assert response.body.include?('<D:displayname>/</D:displayname>')
    # project.identifier should not match when using project names
    assert !response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    assert !response.body.include?("<D:displayname>#{@project1.identifier}</D:displayname>")
    # but the project name should match
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>")
    assert response.body.include?("<D:displayname>#{@project1_name}</D:displayname>")
  end

  def test_propfind_depth0_on_project1_for_non_member
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response :missing
  end

  def test_propfind_depth0_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    assert response.body.include?("<D:displayname>#{@project1.identifier}</D:displayname>")
  end

  def test_propfind_depth0_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response :missing
    xml_http_request :propfind, "/dmsf/webdav/#{@project1_uri}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>")
    assert response.body.include?("<D:displayname>#{@project1_name}</D:displayname>")
  end

  def test_propfind_depth1_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    assert response.body.include?("<D:displayname>#{@project1.identifier}</D:displayname>")
    # Folders
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>")
    assert response.body.include?("<D:displayname>#{@folder1.title}</D:displayname>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>")
    assert response.body.include?("<D:displayname>#{@folder6.title}</D:displayname>")
    # Files
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>")
    assert response.body.include?("<D:displayname>#{@file1.name}</D:displayname>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>")
    assert response.body.include?("<D:displayname>#{@file9.name}</D:displayname>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>")
    assert response.body.include?("<D:displayname>#{@file10.name}</D:displayname>")
  end

  def test_propfind_depth1_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response :missing
    xml_http_request :propfind, "/dmsf/webdav/#{@project1_uri}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>")
    # Folders
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@folder1.title}/</D:href>")
    assert response.body.include?("<D:displayname>#{@folder1.title}</D:displayname>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@folder6.title}/</D:href>")
    assert response.body.include?("<D:displayname>#{@folder6.title}</D:displayname>")
    # Files
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file1.name}</D:href>")
    assert response.body.include?("<D:displayname>#{@file1.name}</D:displayname>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file9.name}</D:href>")
    assert response.body.include?("<D:displayname>#{@file9.name}</D:displayname>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file10.name}</D:href>")
    assert response.body.include?("<D:displayname>#{@file10.name}</D:displayname>")
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names_and_cache
    @project1.name = 'Online Cookbook'
    @project1.save!
    project1_new_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
    project1_new_uri = Addressable::URI.escape(project1_new_name)
    xml_http_request :propfind, "/dmsf/webdav/#{project1_new_uri}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{project1_new_uri}/</D:href>")
    assert response.body.include?("<D:displayname>#{project1_new_name}</D:displayname>")
  end

  def test_propfind_depth0_on_project1_for_admin_with_cache
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    # A new PROPSTATS entry should have been created for project1
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    # Replace the PROPSTATS cache entry and make sure that it is used
    RedmineDmsf::Webdav::Cache.write("PROPSTATS/#{@project1.identifier}", "Cached PROPSTATS/#{@project1.identifier}")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert response.body.include?("Cached PROPSTATS/#{@project1.identifier}")
  end

  def test_propfind_depth1_on_project1_for_admin_with_cache
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Project
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPFIND/#{@project1.id}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>")
    # Folders
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>")
    # Files
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>")
    assert response.body.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>")
    result = RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    assert result
    assert result.include?("<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>")
    # Replace PROPFIND and verify that cached entry is used.
    RedmineDmsf::Webdav::Cache.write("PROPFIND/#{@project1.id}", "Cached PROPFIND/#{@project1.id}")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert response.body.include?("Cached PROPFIND/#{@project1.id}")
    # Delete PROPFIND, replace PROPSTATS for one entry and verify that it is used when creating the response and new cache
    RedmineDmsf::Webdav::Cache.invalidate_item("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    RedmineDmsf::Webdav::Cache.write("PROPSTATS/#{@project1.identifier}", "Cached PROPSTATS/#{@project1.identifier}")
    # One PROPFIND entry is added and one .invalid entry is deleted, so no differenct.
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => "1"})
    assert_response 207 # MultiStatus
    assert response.body.include?("Cached PROPSTATS/#{@project1.identifier}")
    result = RedmineDmsf::Webdav::Cache.read("PROPFIND/#{@project1.id}")
    assert result
    assert result.include?("Cached PROPSTATS/#{@project1.identifier}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
  end

  def test_propfind_depth1_on_project1_for_admin_with_cache_and_locks
    log_user 'admin', 'admin' # login as admin
    assert !User.current.anonymous?, 'Current user is anonymous'
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    # Verify that everything exists in the cache as it should
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    # Lock a file and verify that the PROPSTATS for the file and the PROPFIND were deleted
    assert @file1.lock!, "File failed to be locked by #{User.current.name}"
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    # Unlock a file and verify that the PROPSTATS for the file and the PROPFIND were deleted
    assert @file1.unlock!, "File failed to be unlocked by #{User.current.name}"
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    # Lock a folder and verify that the PROPSTATS for the file and the PROPFIND were deleted
    assert @folder1.lock!, "File failed to be locked by #{User.current.name}"
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    # Unlock a folder and verify that the PROPSTATS for the file and the PROPFIND were deleted
    assert @folder1.unlock!, "File failed to be unlocked by #{User.current.name}"
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil, @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
  end
  
end