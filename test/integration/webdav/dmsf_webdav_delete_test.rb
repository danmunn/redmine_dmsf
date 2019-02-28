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

class DmsfWebdavDeleteTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n  
  
  fixtures :projects, :users, :email_addresses, :members, :member_roles, :roles, 
    :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, 
    :dmsf_locks
   
  def setup
    @admin = credentials 'admin'
    @jsmith = credentials 'jsmith'
    @project1 = Project.find 1
    @project2 = Project.find 2
    @role = Role.find_by(name: 'Manager')
    @folder1 = DmsfFolder.find 1
    @folder6 = DmsfFolder.find 6
    @file1 = DmsfFile.find 1
    @dmsf_webdav = Setting.plugin_redmine_dmsf['dmsf_webdav']
    Setting.plugin_redmine_dmsf['dmsf_webdav'] = true
    @dmsf_webdav_strategy = Setting.plugin_redmine_dmsf['dmsf_webdav_strategy']
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    @dmsf_webdav_use_project_names = Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = false
    @dmsf_storage_directory = Setting.plugin_redmine_dmsf['dmsf_storage_directory']
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = 'files/dmsf'
    FileUtils.cp_r File.join(File.expand_path('../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    @project1.enable_module! :dmsf # Flag module enabled
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
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder6
    assert_kind_of DmsfFile, @file1
    assert_kind_of Role, @role
  end

  def test_not_authenticated
    delete '/dmsf/webdav'
    assert_response :unauthorized
  end

  def test_not_authenticated_project
    delete "/dmsf/webdav/#{@project1.identifier}"
    assert_response :unauthorized
  end

  def test_failed_authentication_global
    delete '/dmsf/webdav', :params => nil, :headers => credentials('admin', 'badpassword')
    assert_response :unauthorized
  end

  def test_failed_authentication
    delete "/dmsf/webdav/#{@project1.identifier}", :params => nil, :headers => credentials('admin', 'badpassword')
    assert_response :unauthorized
  end

  def test_root_folder
    delete '/dmsf/webdav', :params => nil, :headers => @admin
    assert_response :not_implemented
  end

  def test_delete_not_empty_folder
    put "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", :params => nil, :headers => @admin
    assert_response :forbidden
  end

  def test_not_existed_project
    delete '/dmsf/webdav/not_a_project/file.txt', :params => nil, :headers => @admin
    assert_response :not_found
  end

  def test_dmsf_not_enabled
    @project1.disable_module! :dmsf
    delete "/dmsf/webdav/#{@project1.identifier}/test.txt", :params => nil, :headers => @jsmith
    assert_response :not_found # Item does not exist, as project is not enabled.
  end

  def test_delete_when_ro
    Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_ONLY'
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @admin
    assert_response :bad_gateway # Item does not exist, as project is not enabled.
  end

  def test_unlocked_file
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @admin
    assert_response :no_content
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} hasn't been deleted"
  end

  def test_unathorized_user
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :not_found # Without folder_view permission, he will not even be aware of its existence.
    @file1.reload
    assert !@file1.deleted?, "File #{@file1.name} is expected to exist"
  end

  def test_unathorized_user_forbidden
    @role.add_permission! :view_dmsf_folders
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :forbidden # Now jsmith's role has view_folder rights, however they do not hold file manipulation rights.
    @file1.reload
    assert !@file1.deleted?, "File #{@file1.name} is expected to exist"
  end

  def test_view_folder_not_allowed
    @role.add_permission! :file_manipulation
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", :params => nil, :headers => @jsmith
    assert_response :not_found # Without folder_view permission, he will not even be aware of its existence.
    @folder1.reload
    assert !@folder1.deleted?, "Folder #{@folder1.title} is expected to exist"
  end

  def test_folder_manipulation_not_allowed
    @role.add_permission! :view_dmsf_folders
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}", :params => nil, :headers => @jsmith
    assert_response :forbidden # Without manipulation permission, action is forbidden.
    @folder1.reload
    assert !@folder1.deleted?, "Foler #{@folder1.title} is expected to exist"
  end

  def test_folder_delete_by_admin
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", :params => nil, :headers => @admin
    assert_response :success
    @folder6.reload
    assert @folder6.deleted?, "Folder #{@folder1.title} is not expected to exist"
  end

  def test_folder_delete_by_user
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", :params => nil, :headers => @jsmith
    assert_response :success
    @folder6.reload
    assert @folder6.deleted?, "Folder #{@folder1.title} is not expected to exist"
  end

  def test_folder_delete_by_user_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", :params => nil, :headers => @jsmith
    assert_response :not_found
    p1name_uri = Addressable::URI.escape(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
    delete "/dmsf/webdav/#{p1name_uri}/#{@folder6.title}", :params => nil, :headers => @jsmith
    assert_response :success
    @folder6.reload
    assert @folder6.deleted?, "Folder #{@folder1.title} is not expected to exist"
  end

  def test_file_delete_by_administrator
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @admin
    assert_response :success
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} is not expected to exist"
  end

  def test_file_delete_by_user
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_delete
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :success
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} is not expected to exist"
  end

  def test_file_delete_by_user_with_project_names
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_delete
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :not_found
    p1name_uri = Addressable::URI.escape(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
    delete "/dmsf/webdav/#{p1name_uri}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :success
    @file1.reload
    assert @file1.deleted?, "File #{@file1.name} is not expected to exist"
  end

  def test_folder_delete_fragments
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/#frament=HTTP/1.1", :params => nil, :headers => @jsmith
    assert_response :bad_request
  end

  def test_locked_folder
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :folder_manipulation
    @folder6.lock!
    delete "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", :params => nil, :headers => @jsmith
    assert_response :locked
    @folder6.reload
    assert !@folder6.deleted?, "Folder #{@folder6.title} is expected to exist"
  end

  def test_locked_file
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_delete
    @file1.lock!
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :locked
    @file1.reload
    assert !@file1.deleted?, "File #{@file1.name} is expected to exist"
  end

  def test_non_versioned_file
    @role.add_permission! :view_dmsf_folders
    @role.add_permission! :file_delete
    delete "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}", :params => nil, :headers => @jsmith
    assert_response :success
    # The file should be destroyed
    assert_nil DmsfFile.visible.find_by(id: @file1.id)
  end

end