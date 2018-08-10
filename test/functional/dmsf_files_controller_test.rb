# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFilesControllerTest < RedmineDmsf::Test::TestCase 
  
  fixtures :users, :email_addresses, :dmsf_files, :dmsf_file_revisions, 
    :custom_fields, :custom_values, :projects, :roles, :members, :member_roles, 
    :enabled_modules, :dmsf_file_revisions

  def setup
    @project = Project.find_by_id 1
    assert_not_nil @project
    @project.enable_module! :dmsf    
    @file = DmsfFile.find_by_id 1    
    @role = Role.find_by_id 1
    User.current = nil
    @request.session[:user_id] = 2
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.expand_path '../../fixtures/files', __FILE__
  end 
  
  def test_truth
    assert_kind_of Project, @project
    assert_kind_of DmsfFile, @file
    assert_kind_of Role, @role
  end

  def test_show_file_ok
    # Permissions OK
    @role.add_permission! :view_dmsf_files
    get :show, :id => @file.id
    assert_response :success
  end

  def test_show_file_forbidden
    # Missing permissions
    get :show, :id => @file.id
    assert_response :forbidden
  end
  
  def test_view_file_ok
    # Permissions OK
    @role.add_permission! :view_dmsf_files    
    get :view, :id => @file.id   
    assert_response :success
  end
      
  def test_view_file_forbidden
    # Missing permissions
    get :view, :id => @file.id
    assert_response :forbidden
  end

  def delete_forbidden
    # Missing permissions
    delete @file, :commit => false
    assert_response :forbidden
  end

  def delete_locked
    # Permissions OK but the file is locked
    @role.add_permission! :file_delete
    delete @file, :commit => false
    assert_response :redirect
    assert_include l(:error_file_is_locked), flash[:error]
  end

  def delete_ok
    # Permissions OK and not locked
    flash[:error].clear
    @file.unlock!
    delete @file, :commit => false
    assert_response :redirect
    assert_equal 0, flash[:error].size
  end

  def test_obsolete_revision_ok
    @role.add_permission! :file_manipulation
    get :obsolete_revision, :id => @file.last_revision.id
    assert_redirected_to :action => 'show', :id => @file
  end

  def test_obsolete_revision_missing_permissions
    get :obsolete_revision, :id => @file.last_revision.id
    assert :forbiden
  end
  
end