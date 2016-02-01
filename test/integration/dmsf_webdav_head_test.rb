# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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

require File.expand_path('../../test_helper', __FILE__)

class DmsfWebdavHeadTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders

  def setup  
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'    
    DmsfFile.storage_path = File.expand_path '../../fixtures/files', __FILE__
    User.current = nil    
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end

  def test_head_requires_authentication
    head "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
    check_headers_dont_exist
  end

  def test_head_responds_with_authentication
    head "/dmsf/webdav/#{@project1.identifier}", nil, @admin
    assert_response :success
    check_headers_exist
  end

  # Note:
  #   At present we use Rack to serve the file, this makes life easy however it removes the Etag 
  #   header and invalidates the test - where as a folder listing will always not include a last-modified 
  #   (but may include an etag, so there is an allowance for a 1 in 2 failure rate on (optionally) required 
  #   headers)
  def test_head_responds_to_file    
    head "/dmsf/webdav/#{@project1.identifier}/test.txt", nil, @admin
    assert_response :success
    check_headers_exist # Note it'll allow 1 out of the 3 expected to fail
  end

  def test_head_fails_when_file_not_found
    head "/dmsf/webdav/#{@project1.identifier}/not_here.txt", nil, @admin
    assert_response :missing
    check_headers_dont_exist
  end
  
  def test_head_fails_when_folder_not_found
    head '/dmsf/webdav/folder_not_here', nil, @admin
    assert_response :missing
    check_headers_dont_exist
  end

  def test_head_fails_when_project_is_not_enabled_for_dmsf
    head "/dmsf/webdav/#{@project2.identifier}/test.txt", nil, @jsmith
    assert_response :missing
    check_headers_dont_exist
  end

  private
 
  def check_headers_exist
    assert !(response.headers.nil? || response.headers.empty?), 
      'Head returned without headers' # Headers exist?
    values = {}
    values[:etag] = { :optional => true, :content => response.headers['Etag'] }
    values[:content_type] = response.headers['Content-Type']
    values[:last_modified] = { :optional => true, :content => response.headers['Last-Modified'] }
    single_optional = false
    values.each do |key,val|
      if val.is_a?(Hash)
        if (val[:optional].nil? || !val[:optional])
           assert(!(val[:content].nil? || val[:content].empty?), "Expected header #{key} was empty." ) if single_optional
        else
          single_optional = true
        end
      else
        assert !(val.nil? || val.empty?), "Expected header #{key} was empty."
      end
    end
  end

  def check_headers_dont_exist
    assert !(response.headers.nil? || response.headers.empty?), 'Head returned without headers' # Headers exist?
    values = {}
    values[:etag] = response.headers['Etag'];
    values[:last_modified] = response.headers['Last-Modified']
    values.each do |key,val|
      assert (val.nil? || val.empty?), "Expected header #{key} should be empty."
    end
  end

end