# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

require File.expand_path('../../../test_helper', __FILE__)

class DmsfWebdavMkcolTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders

  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find 1
    @project2 = Project.find 2
    @role = Role.find_by(name: 'Manager')
    @folder6 = DmsfFolder.find 6
    @dmsf_webdav = Setting.plugin_redmine_dmsf['dmsf_webdav']
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = true
    @dmsf_webdav_strategy = Setting.plugin_redmine_dmsf['dmsf_webdav_strategy']
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    @dmsf_webdav_use_project_names = Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = false
    @dmsf_storage_directory = Setting.plugin_redmine_dmsf['dmsf_storage_directory']
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = 'files/dmsf'
    FileUtils.cp_r File.join(File.expand_path('../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    User.current = nil        
  end

  def teardown
    # Delete our tmp folder
    begin
      FileUtils.rm_rf DmsfFile.storage_path
    rescue Exception => e
      error e.message
    end
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = @dmsf_webdav
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = @dmsf_webdav_strategy
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = @dmsf_webdav_use_project_names
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = @dmsf_storage_directory
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Role, @role
    assert_kind_of DmsfFolder, @folder6
  end

  def test_mkcol_requires_authentication
    process :mkcol, '/dmsf/webdav/test1'
    assert_response :unauthorized
  end

  def test_mkcol_fails_to_create_folder_at_root_level
    process :mkcol, '/dmsf/webdav/test1', :params => nil, :headers => @admin
    assert_response :method_not_allowed
  end

  def test_should_not_succeed_on_a_non_existant_project
    process :mkcol, '/dmsf/webdav/project_doesnt_exist/test1', :params => nil, :headers => @admin
    assert_response :not_found
  end

  def test_should_not_succed_on_a_non_dmsf_enabled_project
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/folder", :params => nil, :headers => @jsmith
    assert_response :forbidden
  end

  def test_should_not_create_folder_without_permissions
    @project1.enable_module! :dmsf # Flag module enabled
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/folder", :params => nil, :headers => @jsmith
    assert_response :forbidden
  end

  def test_should_fail_to_create_folder_that_already_exists
    @project1.enable_module! :dmsf # Flag module enabled
    @role.add_permission! :folder_manipulation
    @role.add_permission! :view_dmsf_folders
    process :mkcol,
      "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", :params => nil, :headers => @jsmith
    assert_response :method_not_allowed
  end

  def test_should_fail_to_create_folder_for_user_without_rights
    @project1.enable_module! :dmsf # Flag module enabled
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test1", :params => nil, :headers => @jsmith
    assert_response :forbidden
  end

  def test_should_create_folder_for_non_admin_user_with_rights
    @project1.enable_module! :dmsf
    @role.add_permission! :folder_manipulation
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test1", :params => nil, :headers => @jsmith
    assert_response :success # Created
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    project1_uri = Addressable::URI.escape(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test2", :params => nil, :headers => @jsmith
    assert_response :not_found
    process :mkcol, "/dmsf/webdav/#{project1_uri}/test3", :params => nil, :headers => @jsmith
    assert_response :success # Created
  end
  
end