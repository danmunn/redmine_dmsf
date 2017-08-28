# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFolderPermissionsControllerTest < RedmineDmsf::Test::TestCase
  fixtures :users, :dmsf_folders, :projects, :roles, :members, :member_roles, :dmsf_folder_permissions,
           :email_addresses

  def setup
    @project1 = Project.find_by_id 1
    assert_not_nil @project1
    @project1.enable_module! :dmsf
    @folder7 = DmsfFolder.find_by_id 7
    @manager = User.find_by_id 2
    @developer = User.find_by_id 3
    @manager_role = Role.find_by_id 1
    User.current = nil
    @request.session[:user_id] = @manager.id
    @manager_role.add_permission! :view_dmsf_folders
    @manager_role.add_permission! :folder_manipulation
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of DmsfFolder, @folder7
    assert_kind_of User, @manager
    assert_kind_of User, @developer
    assert_kind_of Role, @manager_role
  end

  def test_new
    xhr :get, :new, :project_id => @project1, :format => 'js'
    assert_response :success
    assert_template 'new'
    assert_equal 'text/javascript', response.content_type
  end

  def test_autocomplete_for_user
    xhr :get, :autocomplete_for_user, :project_id => @project1, :q => 'smi', :format => 'js'
    assert_response :success
    assert_include 'John Smith', response.body
  end

  def test_append
    xhr :get, :new, :project_id => @project1, :user_ids => [@manager.id], :format => 'js'
    assert_response :success
    assert_template 'new'
    assert_equal 'text/javascript', response.content_type
  end

end
