# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

# WebDAV LOCK test
class DmsfWebdavLockTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def setup
    super
    @xml = %(<?xml version="1.0" encoding="utf-8" ?>
              <d:lockinfo xmlns:d="DAV:">
                <d:lockscope><d:exclusive/></d:lockscope>
                <d:locktype><d:write/></d:locktype>
                <d:owner>jsmith</d:owner>
              </d:lockinfo>)
  end

  def test_lock_file_already_locked_by_other
    log_user 'admin', 'admin'
    process :lock,
            "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}",
            params: @xml,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
    assert_response :locked
  end

  def test_lock_file
    log_user 'jsmith', 'jsmith'
    create_time = Time.utc(2000, 1, 2, 3, 4, 5)
    refresh_time = Time.utc(2000, 1, 2, 6, 7, 8)
    lock_token = nil
    # Time travel, will make the usec part of the time 0
    travel_to create_time do
      # Lock file
      process :lock,
              "/dmsf/webdav/#{@file9.project.identifier}/#{@file9.name}",
              params: @xml,
              headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
      assert_response :success
      # Verify the response
      # <?xml version=\"1.0\"?>
      # <d:prop xmlns:d=\"DAV:\">
      #   <d:lockdiscovery>
      #     <d:activelock>
      #       <d:lockscope><d:exclusive/></d:lockscope>
      #       <d:depth>infinity</d:depth>
      #       <d:timeout>Second-604800</d:timeout>
      #       <d:locktoken>
      #         <d:href>f5762389-6b49-4482-9a4b-ff1c8f975765</d:href>
      #       </d:locktoken>
      #     </d:activelock>
      #   </d:lockdiscovery>
      # </d:prop>
      assert_match %r{<d:lockscope><d:exclusive/></d:lockscope>}, response.body
      assert_match %r{<d:depth>infinity</d:depth>}, response.body
      # 1.week = 7*24*3600=604800 seconds
      assert_match %r{<d:timeout>Second-604800</d:timeout>}, response.body
      assert_match %r{<d:locktoken><d:href>([a-z0-9\-]+)</d:href></d:locktoken>}, response.body
      # Extract the locktoken, needed when refreshing the lock
      response.body =~ %r{<d:locktoken><d:href>([a-z0-9\-]+)</d:href></d:locktoken>}
      lock_token = Regexp.last_match(1)
      # Verify the lock in the db
      @file9.reload
      l = @file9.lock.first
      assert_equal create_time, l.created_at
      assert_equal create_time, l.updated_at
      assert_equal (create_time + 1.week), l.expires_at
    end
    travel_to refresh_time do
      # Refresh lock
      xml = %(<?xml version="1.0" encoding="utf-8" ?>
              <d:lockinfo xmlns:d="DAV:">
                <d:owner>jsmith</d:owner>
              </d:lockinfo>)
      process :lock,
              "/dmsf/webdav/#{@file9.project.identifier}/#{@file9.name}",
              params: xml,
              headers: @jsmith.merge!(
                { HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_IF: "(<#{lock_token}>)" }
              )
      assert_response :success
      # 1.week = 7*24*3600=604800 seconds
      assert_match '<d:timeout>Second-604800</d:timeout>', response.body
      # Verify the lock in the db
      @file9.reload
      l = @file9.lock.first
      assert_equal create_time, l.created_at
      assert_equal refresh_time, l.updated_at
      assert_equal (refresh_time + 1.week), l.expires_at
    end
  end

  def test_lock_file_in_subproject
    log_user 'admin', 'admin'
    process :lock,
            "/dmsf/webdav/#{@file12.project.parent.identifier}/#{@file12.project.identifier}/#{@file12.name}",
            params: @xml,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
    assert_response :success
  end

  def test_lock_folder_in_subproject
    log_user 'admin', 'admin'
    process :lock,
            "/dmsf/webdav/#{@folder10.project.parent.identifier}/#{@folder10.project.identifier}/#{@folder10.title}",
            params: @xml,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
    assert_response :success
  end

  def test_lock_subproject
    log_user 'admin', 'admin'
    process :lock, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}",
            params: @xml,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite' })
    assert_response :multi_status
    assert_match '<d:status>HTTP/1.1 405 Method Not Allowed</d:status>', response.body
  end
end
