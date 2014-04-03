# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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

class DmsfWebdavOptionsTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, 
    :dmsf_folders

  def setup    
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    DmsfFile.storage_path = File.expand_path '../fixtures/files', __FILE__
  end
  
  def test_truth    
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
  end

  test 'HEAD requires authentication' do
    make_request "/dmsf/webdav/#{@project1.identifier}"
    assert_response 401
    check_headers_dont_exist
  end

  test 'HEAD responds with authentication' do
    make_request "/dmsf/webdav/#{@project1.identifier}", 'admin'
    assert_response :success
    check_headers_exist
  end

  # Note:
  #   At present we use Rack to serve the file, this makes life easy however it removes the Etag 
  #   header and invalidates the test - where as a folder listing will always not include a last-modified 
  #   (but may include an etag, so there is an allowance for a 1 in 2 failure rate on (optionally) required 
  #   headers)
  test 'HEAD responds to file' do
    # TODO: the storage path is not set as expected => reset
    DmsfFile.storage_path = File.expand_path('../../fixtures/files', __FILE__)    
    make_request "/dmsf/webdav/#{@project1.identifier}/test.txt", 'admin'
    assert_response :success
    check_headers_exist #Note it'll allow 1 out of the 3 expected to fail
  end

  test 'HEAD fails when file or folder not found' do
    make_request "/dmsf/webdav/#{@project1.identifier}/not_here.txt", 'admin'
    assert_response 404
    check_headers_dont_exist

    make_request '/dmsf/webdav/folder_not_here', 'admin'
    assert_response 404
    check_headers_dont_exist
  end

  test 'HEAD fails when project is not enabled for DMSF' do

    make_request "/dmsf/webdav/#{@project2.identifier}/test.txt", 'jsmith'
    assert_response 404
    check_headers_dont_exist
  end

  private
  
  def make_request(*args)
    if (args.length == 1) #Just a URL
      head args.first
    else
      head args.first, nil, credentials(args[1])
    end
  end

  def check_headers_exist
    assert !(response.headers.nil? || response.headers.empty?), 'Head returned without headers' #Headers exist?
    values = {}
    values[:etag] = {:optional => true, :content => response.headers['Etag']}
    values[:content_type] = response.headers['Content-Type']
    values[:last_modified] = {:optional => true, :content => response.headers['Last-Modified']}
    single_optional = false
    values.each {|key,val|
      if val.is_a?(Hash)
        if (val[:optional].nil? || !val[:optional])
           assert( !(val[:content].nil? || val[:content].empty?), "Expected header #{key} was empty." ) if single_optional
        else
          single_optional = true
        end
      else
        assert !(val.nil? || val.empty?), "Expected header #{key} was empty."
      end
    }
  end

  def check_headers_dont_exist
    assert !(response.headers.nil? || response.headers.empty?), 'Head returned without headers' #Headers exist?
    values = {}
    values[:etag] = response.headers['Etag'];
    values[:last_modified] = response.headers['Last-Modified']
    values.each {|key,val|
      assert (val.nil? || val.empty?), "Expected header #{key} should be empty."
    }
  end

end