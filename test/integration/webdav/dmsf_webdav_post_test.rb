# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

# WebDAV POST tests
class DmsfWebdavPostTest < RedmineDmsf::Test::IntegrationTest
  # Test that any post request is authenticated
  def test_post_request_authenticated
    post '/dmsf/webdav/'
    assert_response :unauthorized
  end

  # Test post is not implemented
  def test_post_not_implemented
    post '/dmsf/webdav/', params: nil, headers: @admin
    assert_response :not_implemented
  end
end
