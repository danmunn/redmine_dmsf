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
    @file5 = DmsfFile.find_by_id 5
    @file9 = DmsfFile.find_by_id 9
    @file10 = DmsfFile.find_by_id 10
    
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
  end
  
  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end
  
  def test_propfind_denied_for_anonymous
    xml_http_request :propfind, "/dmsf/webdav/", nil,
      {:HTTP_DEPTH => "0"}
    assert_response 401
#    puts "\nPROPFIND response.body:\n#{response.body}" unless response.body.nil?
  end
  
  def test_propfind_depth0_on_root_for_non_member
    xml_http_request :propfind, "/dmsf/webdav/", nil,
      @jsmith.merge!({:HTTP_DEPTH => "0"})
      
    assert_response 207 # MultiStatus
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/</D:href>", response.body
    assert_match "<D:displayname>/</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end

  def test_propfind_depth1_on_root_for_non_member
    xml_http_request :propfind, "/dmsf/webdav/", nil,
      @jsmith.merge!({:HTTP_DEPTH => "1"})
      
    assert_response 207 # MultiStatus
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/</D:href>", response.body
    assert_match "<D:displayname>/</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end
  
  def test_propfind_depth0_on_root_for_admin
    xml_http_request :propfind, "/dmsf/webdav/", nil,
      @admin.merge!({:HTTP_DEPTH => "0"})
    
    assert_response 207 # MultiStatus
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/</D:href>", response.body
    assert_match "<D:displayname>/</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end

  def test_propfind_depth1_on_root_for_admin
    xml_http_request :propfind, "/dmsf/webdav/", nil,
      @admin.merge!({:HTTP_DEPTH => "1"})

    assert_response 207 # MultiStatus
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/</D:href>", response.body
    assert_match "<D:displayname>/</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project2.identifier}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@project2.identifier}</D:displayname>", response.body
  end
  
  def test_propfind_depth0_on_project1_for_non_member
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
      @jsmith.merge!({:HTTP_DEPTH => "0"})
    assert_response 404
  end

  def test_propfind_depth0_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
      @admin.merge!({:HTTP_DEPTH => "0"})
    assert_response 207 # MultiStatus
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/</D:href>", response.body
    assert_no_match "<D:displayname>/</D:displayname>", response.body
    # Project
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    # Folders
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@folder1.title}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", response.body
    assert_no_match "<D:displayname>#{@folder6.title}</D:displayname>", response.body
    # Files
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file5.name}</D:href>", response.body
    assert_no_match "<D:displayname>#{@file5.name}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", response.body
    assert_no_match "<D:displayname>#{@file9.name}</D:displayname>", response.body
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", response.body
    assert_no_match "<D:displayname>#{@file10.name}</D:displayname>", response.body
  end
  
  def test_propfind_depth1_on_project1_for_admin
    xml_http_request :propfind, "/dmsf/webdav/#{@project1.identifier}", nil,
      @admin.merge!({:HTTP_DEPTH => "1"})
    assert_response 207 # MultiStatus
    assert_no_match "<D:href>http://www.example.com:80/dmsf/webdav/</D:href>", response.body
    assert_no_match "<D:displayname>/</D:displayname>", response.body
    # Project
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</D:href>", response.body
    assert_match "<D:displayname>#{@project1.identifier}</D:displayname>", response.body
    # Folders
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</D:href>", response.body
    assert_match "<D:displayname>#{@folder1.title}</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</D:href>", response.body
    assert_match "<D:displayname>#{@folder6.title}</D:displayname>", response.body
    # Files
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file5.name}</D:href>", response.body
    assert_match "<D:displayname>#{@file5.name}</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</D:href>", response.body
    assert_match "<D:displayname>#{@file9.name}</D:displayname>", response.body
    assert_match "<D:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</D:href>", response.body
    assert_match "<D:displayname>#{@file10.name}</D:displayname>", response.body
  end
  
end