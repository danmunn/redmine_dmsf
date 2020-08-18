# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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
  
  fixtures :custom_fields, :custom_values, :dmsf_file_revisions

  def setup
    super
    @request.session[:user_id] = @jsmith.id
  end

  def test_show_file_ok
    # Permissions OK
    get :show, params: { id: @file1.id }
    assert_response :success
  end

  def test_show_file_forbidden
    # Missing permissions
    @role_manager.remove_permission! :view_dmsf_files
    get :show, params: { id: @file1.id }
    assert_response :forbidden
  end
  
  def test_view_file_ok
    # Permissions OK
    get :view, params: { id: @file1.id }
    assert_response :success
  end
      
  def test_view_file_forbidden
    # Missing permissions
    @role_manager.remove_permission! :view_dmsf_files
    get :view, params: { id: @file1.id }
    assert_response :forbidden
  end

  def delete_forbidden
    # Missing permissions
    @role_manager.remove_permission! :file_manipulation
    delete @file1, params: { commit: false }
    assert_response :forbidden
  end

  def delete_locked
    # Permissions OK but the file is locked
    delete @file2, params: { commit: false }
    assert_response :redirect
    assert_include l(:error_file_is_locked), flash[:error]
  end

  def delete_ok
    # Permissions OK and not locked
    delete @file1, params: { commit: false }
    assert_response :redirect
    assert_equal 0, flash[:error].size
  end

  def test_obsolete_revision_ok
    get :obsolete_revision, params: { id: @file1.last_revision.id }
    assert_redirected_to action: 'show', id: @file1
  end

  def test_obsolete_revision_missing_permissions
    @role_manager.remove_permission! :file_manipulation
    get :obsolete_revision, params: { id: @file1.last_revision.id }
    assert :forbiden
  end
  
end