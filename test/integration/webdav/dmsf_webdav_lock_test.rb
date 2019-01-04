# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012   Daniel Munn <dan.munn@munnster.co.uk>
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
require 'fileutils'

class DmsfWebdavMoveTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions
    
  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find 1
    @file1 = DmsfFile.find 1
    # Fix permissions for jsmith's role
    @role = Role.find_by(name: 'Manager')
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    @dmsf_webdav = Setting.plugin_redmine_dmsf['dmsf_webdav']
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = true
    @dmsf_webdav_strategy = Setting.plugin_redmine_dmsf['dmsf_webdav_strategy']
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
  end

  def teardown
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = @dmsf_webdav
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = @dmsf_webdav_strategy
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of DmsfFile, @file1
    assert_kind_of Role, @role
  end
  
  def test_lock_file_already_locked_by_other
    log_user 'admin', 'admin' # login as admin
    assert !User.current.anonymous?, 'Current user is anonymous'
    assert @file1.lock!, "File failed to be locked by #{User.current.name}"
    process :lock, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params =>
      %{<?xml version=\"1.0\" encoding=\"utf-8\" ?>
        <d:lockinfo xmlns:d=\"DAV:\">
          <d:lockscope><d:exclusive/></d:lockscope>
          <d:locktype><d:write/></d:locktype>
          <d:owner>jsmith</d:owner>
        </d:lockinfo>},
      :headers => @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
    assert_response :locked
  end
  
  def test_lock_file
    create_time = Time.utc(2000, 1, 2, 3, 4, 5)
    refresh_time = Time.utc(2000, 1, 2, 6, 7, 8)
    locktoken = nil

    # Time travel, will make the usec part of the time 0
    travel_to create_time do
      # Lock file
      xml = %{<?xml version="1.0" encoding="utf-8" ?>
                <d:lockinfo xmlns:d="DAV:">
                  <d:lockscope><d:exclusive/></d:lockscope>
                  <d:locktype><d:write/></d:locktype>
                  <d:owner>jsmith</d:owner>
                </d:lockinfo>}
      process :lock, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => xml,
        :headers => @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
      assert_response :success
      # Verify the response
      # <?xml version=\"1.0\"?>
      # <d:prop xmlns:d=\"DAV:\">
      #   <d:lockdiscovery>
      #     <d:activelock>
      #       <d:lockscope>exclusive</d:lockscope>
      #       <d:locktype>write</d:locktype>
      #       <d:depth>infinity</d:depth>
      #       <d:timeout>Second-604800</d:timeout>
      #       <d:locktoken>
      #         <d:href>f5762389-6b49-4482-9a4b-ff1c8f975765</d:href>
      #       </d:locktoken>
      #     </d:activelock>
      #   </d:lockdiscovery>
      # </d:prop>
      assert_match '<d:lockscope>exclusive</d:lockscope>', response.body
      assert_match '<d:locktype>write</d:locktype>', response.body
      assert_match '<d:depth>infinity</d:depth>', response.body
      # 1.week = 7*24*3600=604800 seconds
      assert_match '<d:timeout>Second-604800</d:timeout>', response.body
      assert_match(/<d:locktoken><d:href>([a-z0-9\-]+)<\/d:href><\/d:locktoken>/, response.body)
      # Extract the locktoken, needed when refreshing the lock
      response.body.match(/<d:locktoken><d:href>([a-z0-9\-]+)<\/d:href><\/d:locktoken>/)
      locktoken = $1
      # Verify the lock in the db
      l = @file1.lock.first
      assert_equal create_time, l.created_at
      assert_equal create_time, l.updated_at
      assert_equal (create_time + 1.week), l.expires_at
    end

    travel_to refresh_time do
      # Refresh lock
      process :lock, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
        :params => nil,
        :headers => @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_IF: locktoken })
      assert_response :success
      # 1.week = 7*24*3600=604800 seconds
      assert_match '<d:timeout>Second-604800</d:timeout>', response.body
      # Verify the lock in the db
      @file1.reload
      l = @file1.lock.first
      assert_equal create_time, l.created_at
      assert_equal refresh_time, l.updated_at
      assert_equal (refresh_time + 1.week), l.expires_at
    end
  end

end