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

# Links controller
class DmsfLinksControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n

  fixtures :dmsf_links, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @file_link = DmsfLink.find 1
    @url_link = DmsfLink.find 5
  end

  def test_authorize_admin
    post '/login', params: { username: 'admin', password: 'admin' }
    get '/dmsf_links/new', params: { project_id: @project1.id }
    assert_response :success
    assert_template 'new'
  end

  def test_authorize_non_member
    post '/login', params: { username: 'someone', password: 'foo' }
    get '/dmsf_links/new', params: { project_id: @project2.id }
    assert_response :forbidden
  end

  def test_authorize_member_ok
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf_links/new', params: { project_id: @project1.id }
    assert_response :success
  end

  def test_authorize_member_no_module
    # Without the module
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @project1.disable_module! :dmsf
    get '/dmsf_links/new', params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_authorize_forbidden
    # Without permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :file_manipulation
    get '/dmsf_links/new', params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_new
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf_links/new', params: { project_id: @project1.id, type: 'link_to' }
    assert_response :success
    assert_select 'label', { text: l(:label_target_project) }
  end

  def test_new_fast_links_enabled
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    member = Member.find_by(user_id: @jsmith.id, project_id: @project1.id)
    assert member
    member.dmsf_fast_links = true
    member.save
    get '/dmsf_links/new', params: { project_id: @project1.id, type: 'link_to' }
    assert_response :success
    assert_select 'label', { count: 0, text: l(:label_target_project) }
  end

  def test_create_file_link_from_f1
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    # 1. File link in a folder from another folder
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        target_project_id: @project2.id,
        dmsf_folder_id: @folder1.id,
        target_file_id: @file6.id,
        target_folder_id: @folder3.id,
        name: 'file_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.id)
  end

  def test_create_file_link_from_f2
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    # 2. File link in a folder from another root folder
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        dmsf_folder_id: @folder1.id,
        target_project_id: @project2.id,
        target_file_id: @file2.id,
        target_folder_id: 'Documents',
        name: 'file_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.id)
  end

  def test_create_file_link_from_f3
    # 3. File link in a root folder from another folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        target_project_id: @project2.id,
        target_file_id: @file6.id,
        target_folder_id: @folder3.id,
        name: 'file_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_create_file_link_from_f4
    # 4. File link in a root folder from another root folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        target_project_id: @project2.id,
        target_file_id: @file2.id,
        name: 'file_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_create_folder_link_from_d1
    # 1. Folder link in a folder from another folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        dmsf_folder_id: @folder1.id,
        target_project_id: @project2.id,
        target_folder_id: @folder3.id,
        name: 'folder_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.id)
  end

  def test_create_folder_link_from_d2
    # 2. Folder link in a folder from another root folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        dmsf_folder_id: @folder1.id,
        target_project_id: @project2.id,
        name: 'folder_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.id)
  end

  def test_create_folder_link_from_d3
    # 3. Folder link in a root folder from another folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        target_project_id: @project2.id,
        target_folder_id: @folder3.id,
        name: 'folder_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_create_folder_link_from_d4
    # 4. Folder link in a root folder from another root folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        target_project_id: @project2.id,
        name: 'folder_link',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_create_file_link_to_f1
    # 1. File link to a root folder from another folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        dmsf_file_id: @file1.id,
        target_project_id: @project2.id,
        target_folder_id: @folder3.id,
        name: 'file_link',
        type: 'link_to'
      } }
    end
    assert_redirected_to dmsf_file_path(@file1.id)
  end

  def test_create_file_link_to_f2
    # 2. File link to a folder from another folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project2.id,
        dmsf_folder_id: @folder3.id,
        target_project_id: @project1.id,
        target_folder_id: @folder1.id,
        dmsf_file_id: @file6.id,
        name: 'file_link',
        type: 'link_to'
      } }
    end
    assert_redirected_to dmsf_file_path(@file6.id)
  end

  def test_create_file_link_to_f3
    # 3. File link to a root folder from another root folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project2.id,
        target_project_id: @project1.id,
        dmsf_file_id: @file6.id,
        name: 'file_link',
        type: 'link_to'
      } }
    end
    assert_redirected_to dmsf_file_path(@file6.id)
  end

  def test_create_file_link_to_f4
    # 4. File link to a folder from another root folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project2.id,
        dmsf_folder_id: @folder3.id,
        target_project_id: @project1.id,
        dmsf_file_id: @file6.id,
        name: 'file_link',
        type: 'link_to'
      } }
    end
    assert_redirected_to dmsf_file_path(@file6.id)
  end

  def test_create_external_link_from
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        target_project_id: @project1.id,
        name: 'file_link',
        external_link: 'true',
        type: 'link_from'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1)
  end

  def test_create_folder_link_to_f1
    # 1. Folder link to a root folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        dmsf_folder_id: @folder1.id,
        target_project_id: @project2.id,
        name: 'folder_link',
        type: 'link_to'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.dmsf_folder_id)
  end

  def test_create_folder_link_to_f2
    # 2. Folder link to a folder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.count', +1 do
      post '/dmsf_links', params: { dmsf_link: {
        project_id: @project1.id,
        dmsf_folder_id: @folder1.id,
        target_project_id: @project2.id,
        target_folder_id: @folder3.id,
        name: 'folder_link',
        type: 'link_to'
      } }
    end
    assert_redirected_to dmsf_folder_path(id: @project1, folder_id: @folder1.dmsf_folder_id)
  end

  def test_destroy
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.visible.count', -1 do
      delete "/dmsf_links/#{@file_link.id}", params: { project_id: @project1.id }
    end
    assert_redirected_to dmsf_folder_path(id: @file_link.project, folder_id: @file_link.dmsf_folder_id)
  end

  def test_destroy_in_subfolder
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    assert_difference 'DmsfLink.visible.count', -1 do
      delete "/dmsf_links/#{@url_link.id}",
             params: { project_id: @url_link.project_id, folder_id: @url_link.dmsf_folder_id }
    end
    assert_redirected_to dmsf_folder_path(id: @url_link.project, folder_id: @url_link.dmsf_folder_id)
  end

  def test_restore_forbidden
    # Missing permissions
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = trash_dmsf_path(id: @project1)
    @role_manager.remove_permission! :file_manipulation
    get "/dmsf/links/#{@file_link.id}/restore", params: { project_id: @project1.id }
    assert_response :forbidden
  end

  def test_restore_ok
    # Permissions OK
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @request.env['HTTP_REFERER'] = trash_dmsf_path(id: @project1)
    get "/dmsf/links/#{@file_link.id}/restore", params: { project_id: @project1.id }
    assert_response :redirect
  end
end
