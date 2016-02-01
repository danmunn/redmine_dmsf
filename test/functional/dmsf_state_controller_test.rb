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

class DmsfStateControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n  
    
  fixtures :users, :email_addresses, :projects, :members, :roles, :member_roles

  def setup
    @user_admin = User.find_by_id 1 # Redmine admin
    @user_member = User.find_by_id 2 # John Smith - manager
    @user_non_member = User.find_by_id 3 # Dave Lopper    
    @project = Project.find_by_id 1
    assert_not_nil @project
    @project.enable_module! :dmsf
    @role_manager = Role.find_by_name('Manager')    
    User.current = nil
  end
  
  def test_truth
    assert_kind_of User, @user_admin
    assert_kind_of User, @user_member
    assert_kind_of User, @user_non_member
    assert_kind_of Project, @project        
    assert_kind_of Role, @role_manager
  end
    
  def test_user_pref_save_member
    # Member    
    @request.session[:user_id] = @user_member.id
    @role_manager.add_permission! :user_preferences
    post :user_pref_save, :id => @project.id, :email_notify => 1, 
      :title_format => '%t_%v'
    assert_redirected_to settings_project_path(@project, :tab => 'dmsf')        
    assert_not_nil flash[:notice]
    assert_equal flash[:notice], l(:notice_your_preferences_were_saved)
  end
  
  def test_user_pref_save_member_forbidden
    # Member
    @request.session[:user_id] = @user_member.id    
    post :user_pref_save, :id => @project.id, :email_notify => 1, 
      :title_format => '%t_%v'
    assert_response :forbidden
  end
  
  def test_user_pref_save_none_member
    # Non Member
    @request.session[:user_id] = @user_non_member.id
    @role_manager.add_permission! :user_preferences
    post :user_pref_save, :id => @project.id, :email_notify => 1, 
      :title_format => '%t_%v'
    assert_response :forbidden
  end
  
  def test_user_pref_save_admin
    # Admin - non member
    @request.session[:user_id] = @user_admin.id
    @role_manager.add_permission! :user_preferences
    post :user_pref_save, :id => @project.id, :email_notify => 1, 
      :title_format => '%t_%v'
    assert_redirected_to settings_project_path(@project, :tab => 'dmsf')        
    assert_not_nil flash[:warning]
    assert_equal flash[:warning], l(:user_is_not_project_member)
  end

end