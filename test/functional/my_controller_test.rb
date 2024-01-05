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

# My controller
class MyControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n

  fixtures :user_preferences, :dmsf_workflows, :dmsf_workflow_steps, :dmsf_workflow_step_assignments,
           :dmsf_workflow_step_actions, :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :dmsf_locks

  def test_page_with_open_approvals_one_approval
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    DmsfFileRevision.where(id: 5).delete_all
    @jsmith.pref[:my_page_layout] = { 'top' => ['open_approvals'] }
    @jsmith.pref.save!
    get '/my/page'
    assert_response :success
    return if defined?(EasyExtensions)

    assert_select 'div#list-top' do
      assert_select 'h3', { text: "#{l(:open_approvals)} (1)" }
    end
  end

  def test_page_with_open_approvals_no_approval
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @jsmith.pref[:my_page_layout] = { 'top' => ['open_approvals'] }
    @jsmith.pref.save!
    get '/my/page'
    assert_response :success
    return if defined?(EasyExtensions)

    assert_select 'div#list-top' do
      assert_select 'h3', { text: "#{l(:open_approvals)} (0)" }
    end
  end

  def test_page_with_open_locked_documents
    post '/login', params: { username: 'admin', password: 'admin' }
    @request.session[:user_id] = @admin.id
    @admin.pref[:my_page_layout] = { 'top' => ['locked_documents'] }
    @admin.pref.save!
    get '/my/page'
    assert_response :success
    return if defined?(EasyExtensions)

    text = l(:locked_documents)
    text << " (0 #{l(:label_number_of_folders).downcase} / 1 #{l(:label_number_of_documents).downcase})"
    assert_select 'div#list-top' do
      assert_select 'h3', { text: text }
    end
  end

  def test_page_with_open_watched_documents
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    @jsmith.pref[:my_page_layout] = { 'top' => ['watched_documents'] }
    @jsmith.pref.save!
    @file1.add_watcher @jsmith
    @folder1.add_watcher @jsmith
    @project1.add_watcher @jsmith
    get '/my/page'
    return if defined?(EasyExtensions)

    assert_response :success
    assert_select 'div#list-top' do
      assert_select 'h3', { text: "#{l(:label_dmsf_watched)} (2/1)" }
    end
  end
end
