# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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
require 'fileutils'

class DmsfWebdavMoveTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions
    
  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find_by_id 1

    # Fix permissions for jsmith's role
    @role = Role.find 1 #
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    
    super
  end
  
  def test_lock_file_already_locked_by_other
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      file = DmsfFile.find_by_id 1

      log_user 'admin', 'admin' # login as admin
      assert !User.current.anonymous?, 'Current user is anonymous'
      assert file.lock!, "File failed to be locked by #{User.current.name}"

      xml_http_request :lock, "/dmsf/webdav/#{@project1.identifier}/#{file.name}",
        "<?xml version=\"1.0\" encoding=\"utf-8\" ?>
  <d:lockinfo xmlns:d=\"DAV:\">
    <d:lockscope><d:exclusive/></d:lockscope>
    <d:locktype><d:write/></d:locktype>
    <d:owner>jsmith</d:owner>
  </d:lockinfo>",
        @jsmith.merge!({:HTTP_DEPTH => 'infinity',
                        :HTTP_TIMEOUT => 'Infinite',})
      assert_response 423 # Locked
    end
  end
  
  def test_lock_file
    if Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] == 'WEBDAV_READ_WRITE'
      file = DmsfFile.find_by_id 1

      create_time = Time.utc(2000, 1, 2, 3, 4, 5)
      refresh_time = Time.utc(2000, 1, 2, 6, 7, 8)

      # Time travel, will make the usec part of the time 0
      travel_to create_time do
        # Lock file
        xml_http_request :lock, "/dmsf/webdav/#{@project1.identifier}/#{file.name}",
          "<?xml version=\"1.0\" encoding=\"utf-8\" ?>
    <d:lockinfo xmlns:d=\"DAV:\">
      <d:lockscope><d:exclusive/></d:lockscope>
      <d:locktype><d:write/></d:locktype>
      <d:owner>jsmith</d:owner>
    </d:lockinfo>",
          @jsmith.merge!({:HTTP_DEPTH => 'infinity',
                          :HTTP_TIMEOUT => 'Infinite',})
        assert_response :success
        # Verify the response
        assert_match '<D:lockscope><D:exclusive/></D:lockscope>', response.body
        assert_match '<D:locktype><D:write/></D:locktype>', response.body
        assert_match '<D:depth>infinity</D:depth>', response.body
        # 1.week = 7*24*3600=604800 seconds
        assert_match '<D:timeout>Second-604800</D:timeout>', response.body
        assert_match(/<D:locktoken><D:href>([a-z0-9\-]+)<\/D:href><\/D:locktoken>/, response.body)
        # Extract the locktoken, needed when refreshing the lock
        response.body.match(/<D:locktoken><D:href>([a-z0-9\-]+)<\/D:href><\/D:locktoken>/)
        locktoken=$1
        # Verify the lock in the db
        l = DmsfFile.find_by_id(1).lock.first
        assert_equal l.created_at, create_time
        assert_equal l.updated_at, create_time
        assert_equal l.expires_at, create_time + 1.week

        travel_to refresh_time do
          # Refresh lock
          xml_http_request :lock, "/dmsf/webdav/#{@project1.identifier}/#{file.name}",
            nil,
            @jsmith.merge!({:HTTP_DEPTH => 'infinity',
                            :HTTP_TIMEOUT => 'Infinite',
                            :HTTP_IF => "(#{locktoken})"})
          assert_response :success
          # 1.week = 7*24*3600=604800 seconds
          assert_match '<D:timeout>Second-604800</D:timeout>', response.body
          # Verify the lock in the db
          l = DmsfFile.find_by_id(1).lock.first
          assert_equal l.created_at, create_time
          assert_equal l.updated_at, refresh_time
          assert_equal l.expires_at, refresh_time + 1.week
        end
      end
    end
  end
end