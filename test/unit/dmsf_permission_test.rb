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

