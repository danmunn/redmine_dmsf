# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

class IssuesControllerTest < RedmineDmsf::Test::TestCase

  fixtures :users, :email_addresses, :user_preferences, :projects, :dmsf_file_revisions, :dmsf_folders,
           :dmsf_files, :projects, :issues, :versions, :trackers, :projects_trackers, :roles, :members, :member_roles,
           :enabled_modules, :enumerations, :issue_statuses

  def setup
    @user_manager = User.find 2
    @project1 = Project.find 1
    @project1.enable_module! :dmsf
    @project1.enable_module! :issue_tracking
    @project2 = Project.find 2
    @project2.enable_module! :dmsf
    @project2.enable_module! :issue_tracking
    @issue1 = Issue.find 1
    @dmsf_storage_directory = Setting.plugin_redmine_dmsf['dmsf_storage_directory']
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = 'files/dmsf'
    FileUtils.cp_r File.join(File.expand_path('../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    User.current = nil
    @request.session[:user_id] = @user_manager.id
  end

  def teardown
    # Delete our tmp folder
    begin
      FileUtils.rm_rf DmsfFile.storage_path
    rescue Exception => e
      error e.message
    end
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = @dmsf_storage_directory
  end
  
  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Issue, @issue1
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
    put :update, :params => {id: @issue1.id, issue: { project_id: @project2.id, tracker_id: '1', priority_id: '6',
        category_id: '3' }}
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