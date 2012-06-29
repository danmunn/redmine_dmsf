require File.expand_path('../../test_helper.rb', __FILE__)

class DmsfFolderTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :enabled_modules, :enumerations

  def test_folder_creating
    assert_not_nil(dmsf_folders(:dmsf_folders_001))
  end
  
end
