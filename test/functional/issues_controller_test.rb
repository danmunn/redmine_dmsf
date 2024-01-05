# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Issues controller
class IssuesControllerTest < RedmineDmsf::Test::TestCase
  fixtures :user_preferences, :issues, :versions, :trackers, :projects_trackers, :issue_statuses,
           :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :enumerations,
           :issue_categories

  def setup
    super
    @issue1 = Issue.find 1
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
  end

  def test_put_update_with_project_change
    # If we move an issue to a different project, attached documents and their system folders must be moved too
    assert_equal @issue1.project, @project1
    system_folder = @issue1.system_folder
    assert system_folder
    assert_equal @project1.id, system_folder.project_id
    main_system_folder = @issue1.main_system_folder
    assert main_system_folder
    assert_equal @project1.id, main_system_folder.project_id
    patch "/issues/#{@issue1.id}",
          params: { issue: { project_id: @project2.id, tracker_id: '1', priority_id: '6', category_id: '3' } }
    assert_redirected_to action: 'show', id: @issue1.id
    @issue1.reload
    assert_equal @project2.id, @issue1.project.id
    system_folder = @issue1.system_folder
    assert system_folder
    assert_equal @project2.id, system_folder.project_id
    main_system_folder = @issue1.main_system_folder
    assert main_system_folder
    assert_equal @project2.id, main_system_folder.project_id
  end
end
