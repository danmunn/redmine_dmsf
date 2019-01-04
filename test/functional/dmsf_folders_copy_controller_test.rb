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

class DmsfFoldersCopyControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n

  fixtures :users, :projects, :roles, :members, :member_roles,:enabled_modules, :dmsf_folders,
           :email_addresses

  def setup
    @project1 = Project.find 1
    @project2 = Project.find 2
    @project5 = Project.find 5
    @project1.enable_module! :dmsf
    @folder1 = DmsfFolder.find 1
    @folder2 = DmsfFolder.find 2
    @folder6 = DmsfFolder.find 6
    @user_admin = User.find 1
    @user_member = User.find 2
    @user_non_member = User.find 3
    @role_manager = Role.where(:name => 'Manager').first
    User.current = nil
    @request.session[:user_id] = @user_member.id  # John Smith - manager
    @dmsf_storage_directory = Setting.plugin_redmine_dmsf['dmsf_storage_directory']
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = 'files/dmsf'
    FileUtils.cp_r File.join(File.expand_path('../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    @project1.enable_module!(:dmsf)
    @role_manager.add_permission! :folder_manipulation
    @role_manager.add_permission! :view_dmsf_folders
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
    assert_kind_of Project, @project5
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder2
    assert_kind_of DmsfFolder, @folder6
    assert_kind_of User, @user_admin
    assert_kind_of User, @user_member
    assert_kind_of User, @user_non_member
    assert_kind_of Role, @role_manager
  end

  def test_authorize_admin
    @request.session[:user_id] = @user_admin.id
    get :new, :params => {:id => @folder1.id}
    assert_response :success
    assert_template 'new'
  end

  def test_authorize_non_member
    @request.session[:user_id] = @user_non_member.id
    get :new, :params => {:id => @folder1.id}
    assert_response :forbidden
  end

  def test_authorize_member_no_module
    @project1.disable_module!(:dmsf)
    get :new, :params => {:id => @folder1.id}
    assert_response :forbidden
  end

  def test_authorize_forbidden
    @role_manager.remove_permission! :folder_manipulation
    get :new, :params => {:id => @folder1.id}
    assert_response :forbidden
  end

  def test_target_folder
    get :new, :params => {:id => @folder1.id, :target_folder_id => @folder2.id}
    assert_response :success
    assert_template 'new'
  end

  def test_target_folder_forbidden
    @role_manager.remove_permission! :view_dmsf_folders
    get :new, :params => {:id => @folder1.id, :target_folder_id => @folder2.id}
    assert_response :forbidden
  end

  def test_target_project
    get :new, :params => {:id => @folder1.id, :target_project_id => @project1.id}
    assert_response :success
    assert_template 'new'
  end

  def test_new
    get :new, :params => {:id => @folder1.id}
    assert_response :success
    assert_template 'new'
  end

  def test_copy
    post :copy, :params => {:id => @folder1.id, :target_project_id => @project1.id, :target_folder_id => @folder6.id}
    assert_response :redirect
    assert_nil flash[:errors]
  end

  def test_copy_to_another_project
    @request.session[:user_id] = @user_admin.id
    @project2.enable_module!(:dmsf)
    assert_equal @project1.id, @folder1.project_id
    post :copy, :params => {:id => @folder1.id, :target_project_id => @project2.id}
    assert_response :redirect
    assert_nil flash[:errors]
    # Check all childs' project ID
    tree = DmsfHelper::all_children_sorted(@project2, 0, 0)
    tree.each do |f, pos|
      assert_equal @project2.id, f.project_id
    end
  end

  def test_copy_the_same_target
    post :copy, :params => {:id => @folder1.id, :target_project_id => @folder1.project.id, :target_folder_id => @folder1.dmsf_folder}
    assert_equal flash[:errors], l(:error_target_folder_same)
    assert_redirected_to :action => 'new', :target_project_id => @folder1.project.id,
                         :target_folder_id => @folder1.dmsf_folder
  end

  def test_copy_to_locked_folder
    post :copy, :params => {:id => @folder1.id, :target_project_id => @folder1.project.id, :target_folder_id => @folder2.id}
    assert_response :forbidden
  end

  def test_copy_to_dmsf_not_enabled
    post :copy, :params => {:id => @folder1.id, :target_project_id => @project5.id, :target_folder_id => nil}
    assert_response :forbidden
  end

  def test_copy_to_dmsf_enabled
    @project5.enable_module!(:dmsf)
    post :copy, :params => {:id => @folder1.id, :target_project_id => @project5.id, :target_folder_id => nil}
    assert_response :redirect
    assert_nil flash[:errors]
  end

  def test_copy_to_as_non_member
    post :copy, :params => {:id => @folder1.id, :target_project_id => @project2.id, :target_folder_id => nil}
    assert_response :forbidden
  end

  def test_move
    post :move, :params => {:id => @folder1.id, :target_project_id => @project1.id, :target_folder_id => @folder6.id}
    assert_response :redirect
    assert_nil flash[:errors]
  end

  def test_move_the_same_target
    post :move, :params => {:id => @folder1.id, :target_project_id => @folder1.project.id, :target_folder_id => @folder1.dmsf_folder}
    assert_equal flash[:errors], l(:error_target_folder_same)
    assert_redirected_to :action => 'new', :target_project_id => @folder1.project.id, :target_folder_id => @folder1.dmsf_folder
  end

  def test_move_to_locked
    @folder1.lock!
    post :move, :params => {:id => @folder1.id, :target_project_id => @folder1.project.id, :target_folder_id => @folder2.id}
    assert_response :forbidden
  end

  def test_move_to_locked_folder
    post :move, :params => {:id => @folder1.id, :target_project_id => @folder2.project.id, :target_folder_id => @folder2.id}
    assert_response :forbidden
  end

  def test_move_to_dmsf_not_enabled
    post :move, :params => {:id => @folder1.id, :target_project_id => @project5.id, :target_folder_id => nil}
    assert_response :forbidden
  end

  def test_move_to_dmsf_enabled
    @project5.enable_module!(:dmsf)
    post :move, :params => {:id => @folder1.id, :target_project_id => @project5.id, :target_folder_id => nil}
    assert_response :redirect
    assert_nil flash[:errors]
  end

  def test_move_to_as_non_member
    post :move, :params => {:id => @folder1.id, :target_project_id => @project2.id, :target_folder_id => nil}
    assert_response :forbidden
  end

  def test_move_to_another_project
    @request.session[:user_id] = @user_admin.id
    @project2.enable_module!(:dmsf)
    assert_equal @project1.id, @folder1.project_id
    post :move, :params => {:id => @folder1.id, :target_project_id => @project2.id}
    assert_response :redirect
    assert_nil flash[:errors]
    # Check all childs' project ID
    tree = DmsfHelper::all_children_sorted(@project2, 0, 0)
    tree.each do |f, pos|
      assert_equal @project2.id, f.project_id
    end
  end

end