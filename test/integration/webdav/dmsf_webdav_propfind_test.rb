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
    
    # Folders in project1/
    @folder1 = DmsfFolder.find_by_id 1
    @folder6 = DmsfFolder.find_by_id 6
    # Files in project1/
    @file1 = DmsfFile.find_by_id 1
    @file9 = DmsfFile.find_by_id 9
    @file10 = DmsfFile.find_by_id 10
    
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    
    # Temporarily enable project names to generate names for project1
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    @project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
    @project1_uri = URI.encode(@project1_name, /\W/)
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = false
    RedmineDmsf::Webdav::Cache.init_nullcache
  end
  
  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end
  
  def test_propfind_denied_for_anonymous
    xml_http_request :propfind, '/dmsf/webdav/', nil,
      {:HTTP_DEPTH => '0'}
    assert_response 401
  end
  
  def test_propfind_depth0_on_root_for_non_member
    xml_http_request :propfind, '/dmsf/webdav/', nil,
      @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
    assert_match '<D:displayname>/</D:displayname>', response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end

  def test_propfind_depth1_on_root_for_non_member
    xml_http_request :propfind, '/dmsf/webdav/', nil,
      @jsmith.merge!({:HTTP_DEPTH => '1'})
      
    assert_response 207 # MultiStatus
    assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
    assert_match '<D:displayname>/</D:displayname>', response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end
  
  def test_propfind_depth0_on_root_for_admin
    xml_http_request :propfind, '/dmsf/webdav/', nil,
      @admin.merge!({:HTTP_DEPTH => '0'})
    
    assert_response 207 # MultiStatus
    assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
    assert_match '<D:displayname>/</D:displayname>', response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end

  def test_propfind_depth1_on_root_for_admin
    xml_http_request :propfind, '/dmsf/webdav/', nil,
      @admin.merge!({:HTTP_DEPTH => '1'})

    assert_response 207 # MultiStatus
    assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
    assert_match 'D:displayname>/</D:displayname>', response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end
  
  def test_propfind_depth1_on_root_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
      xml_http_request :propfind, '/dmsf/webdav/', nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
      assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
      assert_match '<D:displayname>/</D:displayname>', response.body
      # project.identifier should not match when using project names
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
      assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
      # but the project name should match
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>", response.body
      assert_match "<D:displayname>#{@project1_name}</D:displayname>", response.body
    end
  end
  
  def test_propfind_depth0_on_project1_for_non_member
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
      @jsmith.merge!({:HTTP_DEPTH => '0'})
    assert_response 404
  end

  def test_propfind_depth0_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
      @admin.merge!({:HTTP_DEPTH => '0'})
    assert_response 207 # MultiStatus
    assert_no_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
    assert_no_match '<D:displayname>/</D:displayname>', response.body
    # Project
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    # Folders
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@folder1.title}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@folder6.title}</D:displayname>", response.body
    # Files
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>", response.body
    assert_no_match "<D:displayname>#{@file1.name}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", response.body
    assert_no_match "<D:displayname>#{@file9.name}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", response.body
    assert_no_match "<D:displayname>#{@file10.name}</D:displayname>", response.body
  end

  def test_propfind_depth0_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '0'})
      assert_response 404
      xml_http_request :propfind, "/dmsf/webdav/#{@project1_uri}", nil,
        @admin.merge!({:HTTP_DEPTH => '0'})
      assert_response 207 # MultiStatus
      assert_no_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
      assert_no_match '<D:displayname>/</D:displayname>', response.body
      # Project
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
      assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>", response.body
      assert_match "<D:displayname>#{@project1_name}</D:displayname>", response.body
    end
  end
  
  def test_propfind_depth1_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
      @admin.merge!({:HTTP_DEPTH => '1'})
    assert_response 207 # MultiStatus
    assert_no_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
    assert_no_match '<D:displayname>/</D:displayname>', response.body
    # Project
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    # Folders
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", response.body
    assert_match "<D:displayname>#{@folder1.title}</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", response.body
    assert_match "<D:displayname>#{@folder6.title}</D:displayname>", response.body
    # Files
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>", response.body
    assert_match "<D:displayname>#{@file1.name}</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", response.body
    assert_match "<D:displayname>#{@file9.name}</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", response.body
    assert_match "<D:displayname>#{@file10.name}</D:displayname>", response.body
  end
  
  def test_propfind_depth1_on_project1_for_admin_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 404

      xml_http_request :propfind, "/dmsf/webdav/#{@project1_uri}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus

      assert_no_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
      assert_no_match '<D:displayname>/</D:displayname>', response.body

      # Project
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
      assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>", response.body
      assert_match "<D:displayname>#{@project1_name}</D:displayname>", response.body

      # Folders
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@folder1.title}/</D:href>", response.body
      assert_match "<D:displayname>#{@folder1.title}</D:displayname>", response.body
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@folder6.title}/</D:href>", response.body
      assert_match "<D:displayname>#{@folder6.title}</D:displayname>", response.body

      # Files
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file1.name}</D:href>", response.body
      assert_match "<D:displayname>#{@file1.name}</D:displayname>", response.body
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file9.name}</D:href>", response.body
      assert_match "<D:displayname>#{@file9.name}</D:displayname>", response.body
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", response.body
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/#{@file10.name}</D:href>", response.body
      assert_match "<D:displayname>#{@file10.name}</D:displayname>", response.body
    end
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names_and_cache
    RedmineDmsf::Webdav::Cache.init_testcache
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] == true
      # PROPSTATS for / and project1 should be cached.
      assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +2 do
        xml_http_request :propfind, '/dmsf/webdav/', nil,
          @admin.merge!({:HTTP_DEPTH => '1'})
      end

      assert_response 207 # MultiStatus
      assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
      assert_match '<D:displayname>/</D:displayname>', response.body

      # project.identifier should not match when using project names
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
      assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body

      # but the project name should match
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>", response.body
      assert_match "<D:displayname>#{@project1_name}</D:displayname>", response.body

      # Rename project1
      @project1.name = 'Online Cookbook'
      @project1.save!
      project1_new_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_new_uri = URI.encode(project1_new_name, /\W/)

      # PROPSTATS for / is already cached, but a new PROPSTATS should be cached for project1
      assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +1 do
        xml_http_request :propfind, '/dmsf/webdav/', nil,
          @admin.merge!({:HTTP_DEPTH => '1'})
      end

      assert_response 207 # MultiStatus
      assert_match '<D:href>http://www.example.com:80/dmsf/webdav/</D:href>', response.body
      assert_match '<D:displayname>/</D:displayname>', response.body

      # project.identifier should not match when using project names
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
      assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body

      # old project name should not match
      assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1_uri}/</D:href>", response.body
      assert_no_match "<D:displayname>#{@project1_name}</D:displayname>", response.body

      # but new project name should match
      assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{project1_new_uri}/</D:href>", response.body
      assert_match "<D:displayname>#{project1_new_name}</D:displayname>", response.body
    end
  end
  
  def test_propfind_depth0_on_project1_for_admin_with_cache
    RedmineDmsf::Webdav::Cache.init_testcache
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +1 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '0'})
      assert_response 207 # MultiStatus
    end
    
    # Response should be correct
    # Project
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    # A new PROPSTATS entry should have been created for project1
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}")
    
    # Replace the PROPSTATS cache entry and make sure that it is used
    RedmineDmsf::Webdav::Cache.write("PROPSTATS/#{@project1.identifier}", "Cached PROPSTATS/#{@project1.identifier}")
    
    assert_no_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count' do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '0'})
      assert_response 207 # MultiStatus
    end
    assert_match "Cached PROPSTATS/#{@project1.identifier}", response.body
  end
  
  def test_propfind_depth1_on_project1_for_admin_with_cache
    RedmineDmsf::Webdav::Cache.init_testcache
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +7 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
    end
    
    # Project, a new PROPFIND and PROPSTATS should have been created for project1
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", RedmineDmsf::Webdav::Cache.read("PROPFIND/#{@project1.id}")
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}")
    # Folders, new PROPSTATS should be created for each folder.
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@project1.identifier}/#{@folder6.title}")
    # Files, new PROPSTATS should be created for each folder.
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@file1.id}-#{@file1.last_revision.id}")
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@file9.id}-#{@file9.last_revision.id}")
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", RedmineDmsf::Webdav::Cache.read("PROPSTATS/#{@file10.id}-#{@file10.last_revision.id}")
    
    # Replace PROPFIND and verify that cached entry is used.
    RedmineDmsf::Webdav::Cache.write("PROPFIND/#{@project1.id}", "Cached PROPFIND/#{@project1.id}")
    assert_no_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count' do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
      assert_match "Cached PROPFIND/#{@project1.id}", response.body
    end
    
    # Delete PROPFIND, replace PROPSTATS for one entry and verify that it is used when creating the response and new cache
    RedmineDmsf::Webdav::Cache.invalidate_item("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    RedmineDmsf::Webdav::Cache.write("PROPSTATS/#{@project1.identifier}", "Cached PROPSTATS/#{@project1.identifier}")
    # One PROPFIND entry is added and one .invalid entry is deleted, so no differenct.
    assert_no_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count' do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => "1"})
      assert_response 207 # MultiStatus
    end
    assert_match "Cached PROPSTATS/#{@project1.identifier}", response.body
    assert_match "Cached PROPSTATS/#{@project1.identifier}", RedmineDmsf::Webdav::Cache.read("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
  end
  
  def test_propfind_depth1_on_project1_for_admin_with_cache_and_locks
    RedmineDmsf::Webdav::Cache.init_testcache
    
    log_user 'admin', 'admin' # login as admin
    assert !User.current.anonymous?, 'Current user is anonymous'
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +7 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
    end
    
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
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +1 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
    end
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
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +1 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
    end
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
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +1 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
    end
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
    
    assert_difference 'RedmineDmsf::Webdav::Cache.cache.instance_variable_get(:@data).count', +1 do
      xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
        @admin.merge!({:HTTP_DEPTH => '1'})
      assert_response 207 # MultiStatus
    end
    assert RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}")
    assert !RedmineDmsf::Webdav::Cache.exist?("PROPFIND/#{@project1.id}.invalid")
    assert RedmineDmsf::Webdav::Cache.exist?("PROPSTATS/#{@project1.identifier}/#{@folder1.title}")
  end
  
end