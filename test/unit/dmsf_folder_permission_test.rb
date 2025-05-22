# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

# Folder permissions tests
class DmsfFolderPermissionTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_folder_permissions, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @permission1 = DmsfFolderPermission.find 1
  end

  def test_scope
    assert_equal 2, DmsfFolderPermission.all.size
  end

  def test_scope_users
    assert_equal 1, DmsfFolderPermission.users.all.size
  end

  def test_scope_roles
    assert_equal 1, DmsfFolderPermission.roles.all.size
  end

  def test_copy_to
    permission = @permission1.copy_to(@folder1)
    assert permission
    assert_equal @folder1.id, permission.dmsf_folder_id
    assert_equal @permission1.object_id, permission.object_id
    assert_equal @permission1.object_type, permission.object_type
  end
end
