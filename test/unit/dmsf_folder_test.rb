require File.dirname(__FILE__) + '/../test_helper'

class DmsfFolderTest < ActiveSupport::TestCase
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :enabled_modules, :enumerations

  def test_folder_creating
    assert_not_nil(dmsf_folders(:one))
  end
  
end
