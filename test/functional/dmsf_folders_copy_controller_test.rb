# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

  fixtures :dmsf_locks, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @request.session[:user_id] = @jsmith.id
  end

  def test_authorize_admin
    @request.session[:user_id] = @admin.id
    get :new, params: { id: @folder1.id }
    assert_response :success
    assert_template 'new'
  end

  def test_authorize_non_member
    @request.session[:user_id] = @someone.id
    get :new, params: { id: @folder1.id }
    assert_response :not_found
  end

  def test_authorize_member_no_module
    @project1.disable_module! :dmsf
    get :new, params: { id: @folder1.id }
    assert_response :not_found
  end

  def test_authorize_forbidden
    @role_manager.remove_permission! :folder_manipulation
    get :new, params: { id: @folder1.id }
    assert_response :forbidden
  end

  def test_target_folder
    get :new, params: { id: @folder1.id, target_folder_id: @folder2.id }
    assert_response :success
    assert_template 'new'
  end

  def test_target_folder_forbidden
    @role_manager.remove_permission! :view_dmsf_folders
    get :new, params: { id: @folder1.id, target_folder_id: @folder2.id }
    assert_response :not_found
  end

  def test_target_project
    get :new, params: { id: @folder1.id, target_project_id: @project1.id }
    assert_response :success
    assert_template 'new'
  end

  def test_new
    get :new, params: { id: @folder1.id }
    assert_response :success
    assert_template 'new'
  end

  def test_copy
    post :copy, params: { id: @folder1.id, target_project_id: @project1.id, target_folder_id: @folder6.id }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_copy_to_another_project
    @request.session[:user_id] = @admin.id
    assert_equal @project1.id, @folder1.project_id
    post :copy, params: { id: @folder1.id, target_project_id: @project2.id }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_copy_the_same_target
    post :copy, params: { id: @folder6.id, target_project_id: @folder6.project.id }
    assert_equal flash[:error], l(:error_target_folder_same)
    assert_redirected_to action: :new, target_project_id: @folder6.project.id
  end

  def test_copy_to_locked_folder
    @request.session[:user_id] = @admin.id
    post :copy, params: { id: @folder6.id, target_project_id: @folder2.project.id, target_folder_id: @folder2.id }
    assert_response :forbidden
  end

  def test_copy_to_dmsf_not_enabled
    @project2.disable_module! :dmsf
    post :copy, params: { id: @folder6.id, target_project_id: @project2.id }
    assert_response :forbidden
  end

  def test_copy_to_dmsf_enabled
    post :copy, params: { id: @folder6.id, target_project_id: @project2.id }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_copy_to_as_non_member
    @request.session[:user_id] = @someone.id
    post :copy, params: { id: @folder6.id, target_project_id: @folder1.project.id, target_folder_id: @folder1.id }
    assert_response :not_found
  end

  def test_move
    post :move, params: { id: @folder6.id, target_project_id: @folder1.project.id, target_folder_id: @folder1.id }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_move_to_another_project
    post :move, params: { id: @folder6.id, target_project_id: @project2.id }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_move_the_same_target
    post :move, params: { id: @folder6.id, target_project_id: @folder6.project.id }
    assert_equal flash[:error], l(:error_target_folder_same)
    assert_redirected_to action: :new, target_project_id: @folder6.project.id
  end

  def test_move_locked_folder
    @request.session[:user_id] = @admin.id
    post :move, params: { id: @folder2.id, target_project_id: @folder6.project.id, target_folder_id: @folder6.id }
    assert_response :forbidden
  end

  def test_move_to_locked_folder
    @request.session[:user_id] = @admin.id
    post :move, params: { id: @folder6.id, target_project_id: @folder2.project.id, target_folder_id: @folder2.id }
    assert_response :forbidden
  end

  def test_move_to_dmsf_not_enabled
    @project2.disable_module! :dmsf
    post :move, params: { id: @folder6.id, target_project_id: @project2.id }
    assert_response :forbidden
  end

  def test_move_to_dmsf_enabled
    post :move, params: { id: @folder6.id, target_project_id: @project2.id }
    assert_response :redirect
    assert_nil flash[:error]
  end

  def test_move_to_as_non_member
    @request.session[:user_id] = @someone.id
    post :move, params: { id: @folder6.id, target_project_id: @folder1.project.id, target_folder_id: @folder1.id }
    assert_response :not_found
  end

end