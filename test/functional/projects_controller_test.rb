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

class ProjectsControllerTest < RedmineDmsf::Test::TestCase

  include Redmine::I18n

  def test_settings_dms_member
    @request.session[:user_id] = @jsmith.id
    @role_manager.add_permission! :user_preferences
    with_settings plugin_redmine_dmsf: {'dmsf_act_as_attachable' => '1'} do
      get :settings, params: { id: @project1.id, tab: 'dmsf' }
    end
    assert_response :success
    assert_select 'fieldset legend', text: l(:link_user_preferences)
    assert_select 'fieldset legend', text: "#{l(:field_project)} #{l(:label_preferences)}"
  end

  def test_settings_dms_member_no_permission
    @request.session[:user_id] = @jsmith.id
    @role_manager.remove_permission! :user_preferences
    get :settings, params: { id: @project1.id, tab: 'dmsf' }
    assert_response :success
    assert_select 'fieldset legend', text: l(:link_user_preferences), count: 0
  end

  def test_settings_dms_non_member
    @request.session[:user_id] = @admin.id
    get :settings, params: { id: @project1.id, tab: 'dmsf' }
    assert_response :success
    assert_select 'fieldset legend', text: l(:link_user_preferences), count: 0
  end

  def test_settings_dms_member_no_act_as_attachments
    @request.session[:user_id] = @jsmith.id
    @role_manager.add_permission! :user_preferences
    get :settings, params: { id: @project1.id, tab: 'dmsf' }
    assert_response :success
    assert_select 'fieldset legend', text: "#{l(:field_project)} #{l(:label_preferences)}", count: 0
  end

end