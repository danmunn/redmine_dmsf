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

require File.expand_path('../../test_helper', __FILE__)

# Public URL controller
class DmsfPublicUrlsControllerTest < RedmineDmsf::Test::TestCase
  fixtures :dmsf_public_urls, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_show_valid_url
    get '/dmsf_public_urls', params: { token: 'd8d33e21914a433b280fdc94450ee212' }
    assert_response :success
  end

  def test_show_url_width_invalid_token
    get '/dmsf_public_urls', params: { token: 'f8d33e21914a433b280fdc94450ee212' }
    assert_response :not_found
  end

  def test_show_url_that_has_expired
    get '/dmsf_public_urls', params: { token: 'e8d33e21914a433b280fdc94450ee212' }
    assert_response :not_found
  end
end
