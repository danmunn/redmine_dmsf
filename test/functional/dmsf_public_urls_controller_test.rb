# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@lbcfree.net>
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

class DmsfPublicUrlsControllerTest < RedmineDmsf::Test::TestCase

  fixtures :dmsf_files, :dmsf_file_revisions, :dmsf_public_urls
  
  def setup
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.expand_path '../../fixtures/files', __FILE__
  end

  def test_show_valid_url
    get :show, :token => 'd8d33e21914a433b280fdc94450ee212'
    assert_response :success
  end

  def test_show_url_width_invalid_token
    get :show, :token => 'f8d33e21914a433b280fdc94450ee212'
    assert_response :missing
  end

  def test_show_url_that_has_expired
    get :show, :token => 'e8d33e21914a433b280fdc94450ee212'
    assert_response :missing
  end

end
