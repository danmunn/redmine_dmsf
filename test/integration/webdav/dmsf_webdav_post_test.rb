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
