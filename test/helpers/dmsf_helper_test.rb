# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2019  Jean-Philippe Lang
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

class DmsfHelperTest < RedmineDmsf::Test::HelperTest
  include DmsfHelper

  fixtures :dmsf_folders

  def test_webdav_url
    base_url = ["#{Setting.protocol}:/", Setting.host_name, 'dmsf', 'webdav'].join('/')
    assert_equal "#{base_url}/", webdav_url(nil, nil)
    assert_equal "#{base_url}/ecookbook/", webdav_url(@project1, nil)
    assert_equal "#{base_url}/ecookbook/folder1/", webdav_url(@project1, @folder1)
    with_settings plugin_redmine_dmsf: {'dmsf_webdav_use_project_names' => '1'} do
      assert_equal "#{base_url}/eCookbook 1/", webdav_url(@project1, nil)
    end
  end

end
