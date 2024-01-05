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

# Projects controller
class ProjectsControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n

  def test_settings_dms_member
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.add_permission! :user_preferences
    with_settings plugin_redmine_dmsf: { 'dmsf_act_as_attachable' => '1' } do
      get "/projects/#{@project1.id}/settings", params: { tab: 'dmsf' }
    end
    assert_response :success
    assert_select 'fieldset legend', text: l(:link_user_preferences)
    assert_select 'fieldset legend', text: "#{l(:field_project)} #{l(:label_preferences)}"
  end

  def test_settings_dms_member_no_permission
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.remove_permission! :user_preferences
    get "/projects/#{@project1.id}/settings", params: { tab: 'dmsf' }
    assert_response :success
    assert_select 'fieldset legend', text: l(:link_user_preferences), count: 0
  end

  def test_settings_dms_non_member
    post '/login', params: { username: 'admin', password: 'admin' }
    get "/projects/#{@project1.id}/settings", params: { tab: 'dmsf' }
    assert_response :success
    assert_select 'fieldset legend', text: l(:link_user_preferences), count: 0
  end

  def test_settings_dms_member_no_act_as_attachments
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.add_permission! :user_preferences
    get "/projects/#{@project1.id}/settings", params: { tab: 'dmsf' }
    assert_response :success
    assert_select 'label', text: l(:label_act_as_attachable), count: 0
  end

  def test_legacy_notifications
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @role_manager.add_permission! :user_preferences
    with_settings notified_events: ['dmsf_legacy_notifications'] do
      get "/projects/#{@project1.id}/settings", params: { tab: 'dmsf' }
      assert_response :success
      assert_select 'label', text: l(:label_notifications)
    end
  end
end
