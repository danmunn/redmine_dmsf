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

class DmsfFolderPermissionsControllerTest < RedmineDmsf::Test::TestCase

  fixtures :dmsf_folder_permissions, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @request.session[:user_id] = @jsmith.id
  end

  def test_new
    get :new, params: { project_id: @project1, dmsf_folder_id: @folder7, format: 'js' }, xhr: true
    assert_response :success
    assert_template 'new'
    assert_equal 'text/javascript', response.content_type
  end

  def test_autocomplete_for_user
    get :autocomplete_for_user, params: { project_id: @project1, dmsf_folder_id: @folder7, q: 'smi', format: 'js' },
        xhr: true
    assert_response :success
    assert_include @jsmith.name, response.body
  end

  def test_append
    get :new, params: { project_id: @project1, dmsf_folder_id: @folder7, user_ids: [@jsmith.id], format: 'js' },
        xhr: true
    assert_response :success
    assert_template 'new'
    assert_equal 'text/javascript', response.content_type
  end

end
