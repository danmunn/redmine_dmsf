# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

class DmsfContextMenusControllerTest < RedmineDmsf::Test::TestCase
  include Redmine::I18n  
    
  fixtures :users, :email_addresses, :projects, :members, :roles, :member_roles, :dmsf_folders,
           :dmsf_files, :dmsf_file_revisions

  def setup
    @user_member = User.find 2 # John Smith - manager
    @project1 = Project.find 1
    @project1.enable_module! :dmsf
    @file1 = DmsfFile.find 1
    @folder1 = DmsfFolder.find 1
    User.current = nil
    @request.session[:user_id] = @user_member.id
  end
  
  def test_truth
    assert_kind_of User, @user_member
    assert_kind_of Project, @project1
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFolder, @folder1
  end
    
  def test_dmsf
    get :dmsf, :params => {:id => @project1.id, :ids => ["file-#{@file1.id}"]}
    assert_response :success
    assert_select 'a.icon-edit', :text => l(:button_edit)
    assert_select 'a.icon-del', :text => l(:button_delete)
    assert_select 'a.icon-download', :text => l(:button_download)
    assert_select 'a.icon-email', :text => l(:field_mail)
  end

  def test_dmsf_no_edit
    get :dmsf, :params => {:id => @project1.id, :ids => ["folder-#{@folder1.id}"]}
    assert_response :success
    assert_select 'a.icon-edit', :text => l(:button_edit), :count => 0
    assert_select 'a.icon-del', :text => l(:button_delete)
    assert_select 'a.icon-download', :text => l(:button_download)
    assert_select 'a.icon-email', :text => l(:field_mail)
  end

  def test_trash
    get :trash, :params => {:id => @project1.id, :ids => ["file-#{@file1.id}"]}
    assert_response :success
    assert_select 'a.icon-cancel', :text => l(:title_restore)
    assert_select 'a.icon-del', :text => l(:button_delete)
  end

end