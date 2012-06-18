require File.expand_path('../../test_helper', __FILE__)

class DmsfWebdavIntegrationTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :member_roles, :roles, :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    @headers = credentials('admin')
    super
  end

  def teardown
    @headers = nil
  end

  test "should deny anonymous" do
    get 'dmsf/webdav'
    assert_response 401
  end

  test "should deny failed authentication" do
    get 'dmsf/webdav', nil, credentials('admin', 'badpassword')
    assert_response 401
  end

  test "should permit authenticated user" do
    get 'dmsf/webdav', nil, @headers
    assert_response :success
  end

  test "should list DMSF enabled project" do

    get 'dmsf/webdav', nil, @headers
    assert_response :success

    assert !response.body.match(Project.find(1).name).nil?, "Expected to find project #{Project.find(1).name} in return data"
  end

  test "should not list non-DMSF enabled project" do

    get 'dmsf/webdav', nil, @headers
    assert_response :success

    assert response.body.match(Project.find(2).name).nil?, "Unexpected find of project #{Project.find(2).name} in return data"
  end

  test "should return status 404 when accessing non-existant or non dmsf-enabled project" do

    ## Test project resource object

    get 'dmsf/webdav/project_does_not_exist', nil, @headers 
    assert_response 404

    get "dmsf/webdav/#{Project.find(2).identifier}", nil, @headers
    assert_response 404


    ## Test dmsf resource object

    get 'dmsf/webdav/project_does_not_exist/test1', nil, @headers
    assert_response 404

    get "dmsf/webdav/#{Project.find(2).identifier}/test.txt", nil, @headers
    assert_response 404
  end

  test "download file from DMSF enabled project" do
    DmsfFile.storage_path = File.expand_path('../../fixtures/files', __FILE__)
    get "dmsf/webdav/#{Project.find(1).identifier}/test.txt", nil, @headers
    assert_response 200
    assert (response.body != "1234"), "File downloaded with expected contents"
  end

  test "should list dmsf contents within \"#{Project.find(1).identifier}\"" do
    get "dmsf/webdav/#{Project.find(1).identifier}", nil, @headers
    assert_response :success
    assert !response.body.match(DmsfFolder.find(1).title).nil?, "Expected to find #{DmsfFolder.find(1).title} in return data"
    assert !response.body.match(DmsfFile.find(1).name).nil?, "Expected to find #{DmsfFile.find(1).name} in return data"
  end

  test "user assigned to project" do

    #We'll be using project 2 and user jsmith for this test (Manager)
    project = Project.find(2)
    role = Role.find(2) #Developer role
    jsmith = credentials('jsmith')
    user = User.find(2)

    get "dmsf/webdav/#{project.identifier}", nil, jsmith
    assert_response 404

    project.enable_module! :dmsf #Flag module enabled

    get "dmsf/webdav/#{project.identifier}", nil, jsmith
    assert_response 404

    role.add_permission! :view_dmsf_folders #assign rights

    get "dmsf/webdav/#{project.identifier}", nil, jsmith
    assert_response :success

    get "dmsf/webdav/#{project.identifier}/test.txt", nil, jsmith
    assert_response 403 #Access is not granted as does not hold view_dmsf_files role (yet)

    role.add_permission! :view_dmsf_files #assign rights

    get "dmsf/webdav/#{project.identifier}/test.txt", nil, jsmith
    assert_response :success
    assert (response.body != "1234"), "File downloaded with expected contents"

    #tear down
    project.disable_module! :dmsf
    role.remove_permission! :view_dmsf_folders
    role.remove_permission! :view_dmsf_files
    
  end

end
