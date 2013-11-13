# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

require File.expand_path('../../test_helper.rb', __FILE__)

class DmsfPermissionTest < RedmineDmsf::Test::UnitTest
  attr_reader :perm
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :enabled_modules, :enumerations
	
  def setup
  end

  test "Static values compute" do
    assert_equal 1, DmsfPermission::READ #Read / Browse
    assert_equal 2, DmsfPermission::WRITE #Write (new file / owned file)
    assert_equal 4, DmsfPermission::MODIFY #Modify existing file/folder - create revision
    assert_equal 8, DmsfPermission::LOCK #Ability to lock/unlock

    assert_equal 7, DmsfPermission::MODIFY | DmsfPermission::WRITE | DmsfPermission::READ
  end

  test "create" do
    
#    DmsfPermission
  end

end

