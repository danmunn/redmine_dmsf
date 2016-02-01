# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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

class MyControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n
    
  fixtures :users, :email_addresses, :user_preferences, :projects,
    :dmsf_workflows, :dmsf_workflow_steps, :dmsf_workflow_step_assignments, 
    :dmsf_file_revisions, :dmsf_folders, :dmsf_files, :dmsf_locks

  def setup
    @user_member = User.find_by_id 2
    assert_not_nil @user_member
    User.current = nil
    @request.session[:user_id] = @user_member.id    
  end 
  
  def test_truth    
    assert_kind_of User, @user_member    
  end
  
  def test_page_with_open_approvals_block    
    @user_member.pref[:my_page_layout] = { 'top' => ['open_approvals'] }
    @user_member.pref.save!    
    get :page
    assert_response :success        
    assert_select 'div#list-top' do      
      assert_select 'h3', { :text => "#{l(:label_my_open_approvals)} (0)" }    
    end      
  end
  
  def test_page_with_open_locked_documents    
    @user_member.pref[:my_page_layout] = { 'top' => ['locked_documents'] }
    @user_member.pref.save!    
    get :page
    assert_response :success
    assert_select 'div#list-top' do      
      assert_select 'h3', { :text => "#{l(:label_my_locked_documents)} (0/1)" }
    end
  end

end