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

# WebDAV UNLOCK tests
class DmsfWebdavUnlockTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def test_unlock_file
    log_user 'admin', 'admin'
    l = @file2.locks.first
    process :unlock,
            "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
  end

  def test_unlock_file_locked_by_someone_else
    log_user 'jsmith', 'jsmith'
    l = @file2.locks.first
    process :unlock,
            "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}",
            params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :forbidden
  end

  def test_unlock_file_with_invalid_token
    log_user 'admin', 'admin'
    process :unlock, "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite',
                                     HTTP_LOCK_TOKEN: 'invalid_token' })
    assert_response :bad_request
  end

  def test_unlock_file_not_locked
    log_user 'admin', 'admin'
    l = @file2.locks.first
    process :unlock,
            "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
    process :unlock,
            "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :no_content
  end

  def test_unlock_folder_wrong_path
    log_user 'jsmith', 'jsmith'
    l = @folder2.locks.first
    # folder1 is missing in the path
    process :unlock,
            "/dmsf/webdav/#{@folder2.project.identifier}/#{@folder2.title}",
            params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :forbidden
  end

  def test_unlock_folder
    log_user 'jsmith', 'jsmith'
    l = @folder2.locks.first
    process :unlock, "/dmsf/webdav/#{@folder2.project.identifier}/#{@folder2.dmsf_folder.title}/#{@folder2.title}",
            params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
  end

  def test_unlock_folder_not_locked
    log_user 'jsmith', 'jsmith' # login as jsmith
    l = @folder2.locks.first
    process :unlock, "/dmsf/webdav/#{@folder2.project.identifier}/#{@folder2.dmsf_folder.title}/#{@folder2.title}",
            params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
    process :unlock, "/dmsf/webdav/#{@folder2.project.identifier}/#{@folder2.dmsf_folder.title}/#{@folder2.title}",
            params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :no_content
  end

  def test_unlock_file_in_subproject
    log_user 'admin', 'admin' # login as admin
    User.current = @admin_user
    l = @file12.lock!
    assert l, "File failed to be locked by #{User.current}"
    process :unlock, "/dmsf/webdav/#{@file12.project.parent.identifier}/#{@file12.project.identifier}/#{@file12.name}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
  end

  def test_unlock_folder_in_subproject
    log_user 'admin', 'admin' # login as admin
    User.current = @admin_user
    l = @folder10.lock!
    assert l, "Folder failed to be locked by #{User.current}"
    process :unlock,
            "/dmsf/webdav/#{@folder10.project.parent.identifier}/#{@folder10.project.identifier}/#{@folder10.title}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
  end
end
