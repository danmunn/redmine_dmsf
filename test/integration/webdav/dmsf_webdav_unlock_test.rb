# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012   Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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

class DmsfWebdavUnlockTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles,
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks
    
  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @admin_user = User.find_by(login: 'admin')
    @jsmith_user = User.find_by(login: 'jsmith')
    @project1 = Project.find 1
    @project1.enable_module! 'dmsf'
    @project2 = Project.find 2
    @project2.enable_module! 'dmsf'
    @project3 = Project.find 3
    @project3.enable_module! 'dmsf'
    @file2 = DmsfFile.find 2
    @file9 = DmsfFile.find 9
    @file12 = DmsfFile.find 12
    @folder2 = DmsfFolder.find 2
    @folder6 = DmsfFolder.find 6
    @folder10 = DmsfFolder.find 10
    # Fix permissions for jsmith's role
    @role = Role.find_by(name: 'Manager')
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    @role.add_permission! :view_dmsf_files
    @role.add_permission! :file_manipulation
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
    assert_kind_of Project, @project2
    assert_kind_of Project, @project3
    assert_kind_of DmsfFile, @file2
    assert_kind_of DmsfFile, @file9
    assert_kind_of DmsfFile, @file12
    assert_kind_of DmsfFolder, @folder2
    assert_kind_of DmsfFolder, @folder6
    assert_kind_of DmsfFolder, @folder10
    assert_kind_of Role, @role
    assert_kind_of User, @admin_user
    assert_kind_of User, @jsmith_user
  end

  def test_unlock_file
    log_user 'admin', 'admin'
    l = @file2.locks.first
    process :unlock, "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}", params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
  end

  def test_unlock_file_locked_by_someone_else
    log_user 'jsmith', 'jsmith'
    l = @file2.locks.first
    process :unlock, "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}", params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :not_found
  end

  def test_unlock_file_with_invalid_token
    log_user 'admin', 'admin'
    process :unlock, "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}", params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: 'invalid_token' })
    assert_response :bad_request
  end

  def test_unlock_file_not_locked
    log_user 'admin', 'admin'
    l = @file2.locks.first
    process :unlock, "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}", params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
    process :unlock, "/dmsf/webdav/#{@file2.project.identifier}/#{@file2.name}", params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :bad_request
  end

  def test_unlock_folder_wrong_path
    log_user 'jsmith', 'jsmith'
    l = @folder2.locks.first
    process :unlock, "/dmsf/webdav/#{@folder2.project.identifier}/#{@folder2.title}", params: nil,
            headers: @jsmith.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :not_found
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
    assert_response :bad_request
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
    process :unlock, "/dmsf/webdav/#{@folder10.project.parent.identifier}/#{@folder10.project.identifier}/#{@folder10.title}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: 'infinity', HTTP_TIMEOUT: 'Infinite', HTTP_LOCK_TOKEN: l.uuid })
    assert_response :success
  end

end