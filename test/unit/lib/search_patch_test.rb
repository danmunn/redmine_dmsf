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

# Search patch tests
class SearchPatchTest < RedmineDmsf::Test::UnitTest
  def test_available_search_types
    assert Redmine::Search.available_search_types.include?('documents')
    return if defined?(EasyExtensions) # It doesn't work with Easy due to alias_method_change

    with_settings plugin_redmine_dmsf: { 'remove_original_documents_module' => '1' } do
      assert_not Redmine::Search.available_search_types.include?('documents')
    end
  end
end
