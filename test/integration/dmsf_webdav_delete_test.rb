require File.expand_path('../../test_helper', __FILE__)

class DmsfWebdavIntegrationTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    DmsfFile.storage_path = File.expand_path("../fixtures/files", __FILE__)
    DmsfLock.delete_all
    @admin = credentials('admin')
    @jsmith = credentials('jsmith')
    super
  end

  test "DELETE denied unless authenticated" do
    delete 'dmsf/webdav'
    assert_response 401

    delete "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401

  end

  test "DELETE denied with failed authentication" do
    delete 'dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401

    delete "dmsf/webdav/#{Project.find(1).identifier}", nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  test "DELETE denied on project folder" do
    delete 'dmsf/webdav/', nil, @admin
    assert_response 501
  end

  test "DELETE denied on folder with children" do
    put "dmsf/webdav/#{Project.find(1).identifier}/folder1", nil, @admin
    assert_response 403 #forbidden
  end

  test "DELETE failed on non-existant project" do
    delete "dmsf/webdav/not_a_project/file.txt", nil, @admin
    assert_response 404 #Item does not exist
  end

  test "DELETE failed on a non-dmsf-enabled project" do
    project = Project.find(2) #Project 2
    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @admin
    assert_response 404 #Item does not exist, as project is not enabled
  end

  test "DELETE succeeds on unlocked file" do
    project = Project.find(1)
    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert !file.nil?, 'File test.txt is expected to exist'

    assert_difference('DmsfFile.project_root_files(project).length', -1) do
      delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @admin
      assert_response :success #If its in the 20x range it's acceptable, should be 204
    end

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.nil?, 'File test.txt is expected to not exist'
  end

  test "DELETE denied on existing file by unauthorised user" do
    project = Project.find(2)
    role = Role.find(2)

    project.enable_module! :dmsf #Flag module enabled

    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @jsmith
    assert_response 404 #Without folder_view permission, he will not even be aware of its existence

    role.add_permission! :view_dmsf_folders

    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @jsmith
    assert_response 403 #Now jsmith's role has view_folder rights, however they do not hold file manipulation rights

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert !file.nil?, 'File test.txt is expected to exist'

    role.remove_permission! :view_dmsf_folders
    project.disable_module! :dmsf

  end

  test "DELETE fails when file_manipulation is granted but view_dmsf_folders is not" do
    project = Project.find(2)
    role = Role.find(2)

    project.enable_module! :dmsf #Flag module enabled
    role.add_permission! :file_manipulation

    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @jsmith
    assert_response 404 #Without folder_view permission, he will not even be aware of its existence

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert !file.nil?, 'File test.txt is expected to exist'

    project.disable_module! :dmsf
  end

  test "DELETE fails on folder without folder_manipulation permission" do
    project = Project.find(2)
    role = Role.find(2)
    folder = DmsfFolder.find(3) #project 2/folder1

    project.enable_module! :dmsf #Flag module enabled
    role.add_permission! :view_dmsf_folders

    assert_no_difference('folder.subfolders.length') do
      delete "dmsf/webdav/#{project.identifier}/folder1/folder2", nil, @jsmith
      assert_response 403 #Without manipulation permission, action is forbidden
    end

    project.disable_module! :dmsf

  end

  test "DELETE folder is successful by administrator" do
    project = Project.find(2)
    folder = DmsfFolder.find(3) #project 2/folder1

    project.enable_module! :dmsf #Flag module enabled

    assert_difference('folder.subfolders.length', -1) do
      delete "dmsf/webdav/#{project.identifier}/folder1/folder2", nil, @admin
      assert_response :success
      folder.reload #We know there is a change, but does the object?
    end


    project.disable_module! :dmsf

  end

  test "DELETE folder is successful by user with roles" do
    project = Project.find(2)
    folder = DmsfFolder.find(3) #project 2/folder1
    role = Role.find(2)

    role.add_permission! :view_dmsf_folders
    role.add_permission! :folder_manipulation

    project.enable_module! :dmsf #Flag module enabled

    assert_difference('folder.subfolders.length', -1) do
      delete "dmsf/webdav/#{project.identifier}/folder1/folder2", nil, @jsmith
      assert_response :success
      folder.reload #We know there is a change, but does the object?
    end

    project.disable_module! :dmsf

  end

  test "DELETE file is successful by administrator" do
    project = Project.find(2)
    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert !file.nil?, 'File test.txt is expected to exist'

    project.enable_module! :dmsf

    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @admin
    assert_response :success

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.nil?, 'File test.txt is expected to not exist'

    project.disable_module! :dmsf

  end

  test "DELETE file is successful by user with correct permissions" do
    project = Project.find(2)
    role = Role.find(2)
    file = DmsfFile.find_file_by_name(project, nil, "test.txt")

    project.enable_module! :dmsf

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation


    assert !file.nil?, 'File test.txt is expected to exist'

    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @jsmith
    assert_response :success

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.nil?, 'File test.txt is expected to not exist'

    project.disable_module! :dmsf
    role.remove_permission! :view_dmsf_folders
    role.remove_permission! :file_manipulation

  end

  test "DELETE fails when file is locked" do
    role = Role.find(2)
    project = Project.find(2)

    project.enable_module! :dmsf #Flag module enabled

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    log_user "admin", "admin" #login as admin

    assert !User.current.anonymous?, "Current user is not anonymous"

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.lock!, "File failed to be locked by #{User.current.name}"

    delete "dmsf/webdav/#{project.identifier}/test.txt", nil, @jsmith
    assert_response 423 #Locked

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert !file.nil?, 'File test.txt is expected to exist'

    User.current = User.find(1) #For some reason the above delete request changes User.current

    file.unlock!
    assert !file.locked?, "File failed to unlock by #{User.current.name}"
    project.disable_module! :dmsf 
    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation


  end



end
