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

# Links helper
class DmsfLinksHelperTest < RedmineDmsf::Test::HelperTest
  include DmsfLinksHelper

  def test_number
    assert DmsfLinksHelper.number?('123')
    assert_not DmsfLinksHelper.number?('-123')
    assert_not DmsfLinksHelper.number?('12.3')
    assert_not DmsfLinksHelper.number?('123a')
    assert_not DmsfLinksHelper.number?(nil)
  end

  def test_default_folder_id_in_files_for_select
    project = Project.find(1)
    assert_nothing_raised do
      files_for_select(project.id)
    end
  end
end
