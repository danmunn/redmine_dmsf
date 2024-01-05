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

# Folder permissions controller
class DmsfFolderPermissionsControllerTest < RedmineDmsf::Test::TestCase
  fixtures :dmsf_folder_permissions, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
  end

  def test_new
    get '/dmsf_folder_permissions/new',
        params: { project_id: @project1.id, dmsf_folder_id: @folder7.id, format: 'js' },
        xhr: true
    assert_response :success
    assert_template 'new'
    assert @response.media_type.include?('text/javascript')
  end

  def test_autocomplete_for_user
    get '/dmsf_folder_permissions/autocomplete_for_user',
        params: { project_id: @project1.id, dmsf_folder_id: @folder7.id, q: 'smi', format: 'js' },
        xhr: true
    assert_response :success
    assert_include @jsmith.name, response.body
  end

  def test_append
    post '/dmsf_folder_permissions/append',
         params: { project_id: @project1.id, dmsf_folder_id: @folder7.id, user_ids: [@jsmith.id], format: 'js' },
         xhr: true
    assert_response :success
    assert_template 'append'
    assert @response.content_type.match?(%r{^text/javascript})
  end
end
