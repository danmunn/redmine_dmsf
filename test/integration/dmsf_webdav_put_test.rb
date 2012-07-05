require File.expand_path('../../test_helper', __FILE__)
require 'fileutils'

class DmsfWebdavIntegrationTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    DmsfLock.delete_all #Delete all locks that are in our test DB - probably not safe but ho hum
    timestamp = DateTime.now.strftime("%y%m%d%H%M")
    DmsfFile.storage_path = File.expand_path("./dmsf_test-#{timestamp}", DmsfHelper.temp_dir)
    Dir.mkdir(DmsfFile.storage_path) unless File.directory?(DmsfFile.storage_path)
    @admin = credentials('admin')
    @jsmith = credentials('jsmith')
    super
  end

  def teardown
    @headers = nil
    #Delete our tmp folder
    begin
      FileUtils.rm_rf DmsfFile.storage_path
    rescue 
      warn "DELETE FAILED"
    end
  end

  test "PUT denied unless authenticated" do
    put 'dmsf/webdav'
    assert_response 401

    put "dmsf/webdav/#{Project.find(1).identifier}"
    assert_response 401

  end

  test "PUT denied with failed authentication" do
    put 'dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401

    put "dmsf/webdav/#{Project.find(1).identifier}", nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  test "PUT denied at root level" do
    put 'dmsf/webdav/test.txt', "1234", @admin.merge!({:content_type => :text})
    assert_response 501
  end

  test "PUT denied on collection/folder" do
    put "dmsf/webdav/#{Project.find(1).identifier}", "1234", @admin.merge!({:content_type => :text})
    assert_response 403 #forbidden
  end

  test "PUT failed on non-existant project" do
    put "dmsf/webdav/not_a_project/file.txt", "1234", @admin.merge!({:content_type => :text})
    assert_response 409 # Conflict, not_a_project does not exist - file.txt cannot be created
  end

  test "PUT as admin granted on dmsf-enabled project" do

    put "dmsf/webdav/#{Project.find(1).identifier}/test-1234.txt", "1234", @admin.merge!({:content_type => :text})
    assert_response 201 #201 Created

    #Lets check for our file
    file = DmsfFile.find_file_by_name(Project.find(1), nil, "test-1234.txt")
    assert !file.nil?, 'Check for files existance'

  end

  test "PUT failed as admin on non-dmsf enabled project" do
    put "dmsf/webdav/#{Project.find(2).identifier}/test-1234.txt", "1234", @admin.merge!({:content_type => :text})
    assert_response 409 #Should report conflict, as project 2 technically doesn't exist if not enabled

    #Lets check for our file
    file = DmsfFile.find_file_by_name(Project.find(2), nil, "test-1234.txt")
    assert file.nil?, 'Check for files existance'
  end

  test "PUT failed when insuficient permissions on project" do

    project = Project.find(2)
    project.enable_module! :dmsf #Flag module enabled
    role = Role.find(2)

    put "dmsf/webdav/#{project.identifier}/test-1234.txt", "1234", @jsmith.merge!({:content_type => :text})
    assert_response 409 #We don't hold the permission view_dmsf_folders, and thus project 2 doesn't exist to us.

    role.add_permission! :view_dmsf_folders 

    put "dmsf/webdav/#{project.identifier}/test-1234.txt", "1234", @jsmith.merge!({:content_type => :text})
    assert_response 403 #We don't hold the permission file_manipulation - so we're unable to do anything with files

    role.remove_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    #Check we don't have write access even if we do have the file_manipulation permission
    put "dmsf/webdav/#{project.identifier}/test-1234.txt", "1234", @jsmith.merge!({:content_type => :text})
    assert_response 409 #We don't hold the permission view_dmsf_folders, and thus project 2 doesn't exist to us.

    #Lets check for our file
    file = DmsfFile.find_file_by_name(project, nil, "test-1234.txt")
    assert file.nil?, 'File test-1234 was found in projects dmsf folder.'

    role.remove_permission! :view_dmsf_folders
    role.remove_permission! :file_manipulation
  end

  test "PUT succeeds for non-admin with correct permissions" do
    project = Project.find(2)
    project.enable_module! :dmsf #Flag module enabled
    role = Role.find(2)

    put "dmsf/webdav/#{project.identifier}/test-1234.txt", "1234", @jsmith.merge!({:content_type => :text})
    assert_response 409 #We don't hold the permission view_dmsf_folders, and thus project 2 doesn't exist to us.

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    #Check we don't have write access even if we do have the file_manipulation permission
    put "dmsf/webdav/#{project.identifier}/test-1234.txt", "1234", @jsmith.merge!({:content_type => :text})
    assert_response 201 #Now we have permissions :D

    #Lets check for our file
    file = DmsfFile.find_file_by_name(project, nil, "test-1234.txt")
    assert !file.nil?, 'File test-1234 was not found in projects dmsf folder.'

    role.remove_permission! :view_dmsf_folders
    role.remove_permission! :file_manipulation
  end

  test "PUT writes revision successfully for unlocked file" do
    project = Project.find(2)
    project.enable_module! :dmsf #Flag module enabled
    role = Role.find(2)

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert_difference('file.revisions.count') do
      put "dmsf/webdav/#{project.identifier}/test.txt", "1234", @jsmith.merge!({:content_type => :text})
      assert_response 201 #Created
    end

    role.remove_permission! :view_dmsf_folders
    role.remove_permission! :file_manipulation

  end

  test "PUT fails revision when file is locked" do
    role = Role.find(2)
    project = Project.find(2)

    project.enable_module! :dmsf #Flag module enabled

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    log_user "admin", "admin" #login as jsmith
    assert !User.current.anonymous?, "Current user is not anonymous"

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.lock!, "File failed to be locked by #{User.current.name}"

    assert_no_difference('file.revisions.count') do
      put "dmsf/webdav/#{project.identifier}/test.txt", "1234", @jsmith.merge!({:content_type => :text})
      assert_response 423 #Locked
    end

    User.current = User.find(1)
    file.unlock!
    
    assert !file.locked?, "File failed to unlock by #{User.current.name}"

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

  end

  test "PUT fails revision when file is locked and user is administrator" do
    role = Role.find(2)
    project = Project.find(2)

    project.enable_module! :dmsf #Flag module enabled

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    log_user "jsmith", "jsmith" #login as jsmith
    assert !User.current.anonymous?, "Current user is not anonymous"

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.lock!, "File failed to be locked by #{User.current.name}"

    assert_no_difference('file.revisions.count') do
      put "dmsf/webdav/#{project.identifier}/test.txt", "1234", @admin.merge!({:content_type => :text})
      assert_response 423 #Created
    end
    User.current = User.find(2)
    begin
      file.unlock!
    rescue
      #nothing
    end
    assert !file.locked?, "File failed to unlock by #{User.current.name}"

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation
  end

  test "PUT accepts revision when file is locked and user is same as lock holder" do
    role = Role.find(2)
    project = Project.find(2)

    project.enable_module! :dmsf #Flag module enabled

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation

    log_user "jsmith", "jsmith" #login as jsmith
    assert !User.current.anonymous?, "Current user is not anonymous"

    file = DmsfFile.find_file_by_name(project, nil, "test.txt")
    assert file.lock!, "File failed to be locked by #{User.current.name}"

    assert_difference('file.revisions.count') do
      put "dmsf/webdav/#{project.identifier}/test.txt", "1234", @jsmith.merge!({:content_type => :text})
      assert_response 201 #Created
    end

    file.unlock!

    assert !file.locked?, "File failed to unlock by #{User.current.name}"

    role.add_permission! :view_dmsf_folders
    role.add_permission! :file_manipulation
  end
end
