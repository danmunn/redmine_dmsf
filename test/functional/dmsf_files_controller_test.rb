# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2013   Karel Pičman <karel.picman@kontron.com>
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
  
  fixtures :users, :dmsf_files, :dmsf_file_revisions, :custom_fields, 
    :custom_values, :projects, :members, :member_roles, :enabled_modules,
    :dmsf_file_revisions

  def setup
    @request.session[:user_id] = 2    
    @file = DmsfFolder.find_by_id 1    
    @role = Role.find_by_id 1
    @custom_field = CustomField.find_by_id 21
    @custom_value_2 = CustomValue.find_by_id 22
  end 
    
  def test_show_file
    # Missing permissions
    get :show, :id => @file
    assert_response 403    
    
    # Permissions OK
    @role.add_permission! :view_dmsf_files
    @role.add_permission! :file_manipulation
    get :show, :id => @file    
    assert_response :success
    
    # The last revision
    assert_select 'label', {:text => @custom_field.name}
    assert_select '.customfield', {:text => "#{@custom_field.name}: #{@custom_value_2.value}"}
    
    # A new revision
    assert_select 'label', {:text => @custom_field.name}
    assert_select 'option', {:value => @custom_value_2.value}
  end
end

