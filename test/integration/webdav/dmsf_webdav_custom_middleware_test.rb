# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

require File.expand_path('../../../test_helper', __FILE__)

# Custom middleware test
class DmsfWebdavCustomMiddlewareTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders, :dmsf_files

  def test_options_for_root_path
    process :options, '/'
    assert_response :method_not_allowed
  end

  def test_options_for_dmsf_root_path
    process :options, '/dmsf'
    assert_response :method_not_allowed
  end

  def test_propfind_for_root_path
    process :propfind, '/'
    assert_response :method_not_allowed
  end

  def test_propfind_for_dmsf_root_path
    process :propfind, '/dmsf'
    assert_response :method_not_allowed
  end

  def test_webdav_not_enabled
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav' => nil } do
      process :options, '/dmsf/webdav'
      assert_response :not_found
    end
  end

  def test_webdav_enabled
    process :options, '/dmsf/webdav'
    assert_response :success
  end
end
