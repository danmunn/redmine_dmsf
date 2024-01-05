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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

# Query tests
class DmsfQueryTest < RedmineDmsf::Test::UnitTest
  fixtures :queries, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @query401 = Query.find 401
    User.current = @jsmith
  end

  def test_typetest_dmsf_nodes
    assert_equal 'DmsfQuery', @query401.type
  end

  def test_available_columns
    n = DmsfQuery.available_columns.size + DmsfFileRevisionCustomField.visible.all.size
    assert_equal n, @query401.available_columns.size
  end

  def test_dmsf_count
    n = DmsfFolder.visible.where(project_id: @project1.id).where("title LIKE '%test%'").all.size +
        DmsfFile.visible.where(project_id: @project1.id).where("name LIKE '%test%'").all.size +
        DmsfLink.visible.where(project_id: @project1.id).where("name LIKE '%test%'").all.size
    assert_equal n - 1, @query401.dmsf_count # One folder is not visible due to the permissions
  end

  def test_dmsf_nodes
    assert @query401.dmsf_nodes.any?
  end

  def test_default
    # User
    @jsmith.pref.default_dmsf_query = @query401.id
    assert_equal @query401, DmsfQuery.default
    @jsmith.pref.default_dmsf_query = nil

    # Project
    @project1.default_dmsf_query_id = @query401.id
    assert_equal @query401, DmsfQuery.default(@project1)
    @project1.default_dmsf_query_id = nil

    # Global
    with_settings plugin_redmine_dmsf: { 'dmsf_default_query' => @query401.id } do
      assert_equal @query401, DmsfQuery.default
    end
  end

  def test_groupable_columns
    assert_not @query401.groupable_columns.any?
  end
end
