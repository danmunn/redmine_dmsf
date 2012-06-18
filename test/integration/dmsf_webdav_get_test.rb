require File.expand_path('../../test_helper', __FILE__)

class DmsfWebdavIntegrationTest < RedmineDmsf::Test::IntegrationTest

  fixtures :projects, :users, :members, :enabled_modules, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

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

    assert response.body.match(Project.find(3).name).nil?, "Unexpected find of project #{Project.find(3).name} in return data"
  end

  test "should return status 404 when accessing non-existant or non dmsf-enabled project" do
    get 'dmsf/webdav/project_does_not_exist/test1', nil, @headers
    assert_response 404

    get "dmsf/webdav/#{Project.find(3).identifier}", nil, @headers
STDOUT.puts response.body
    assert_response 404

  end

  test "should list dmsf contents within \"#{Project.find(1).identifier}\"" do
    get "dmsf/webdav/#{Project.find(1).identifier}", nil, @headers
    assert_response :success
    assert !response.body.match(DmsfFolder.find(1).title).nil?, "Expected to find #{DmsfFolder.find(1).title} in return data"
    assert !response.body.match(DmsfFile.find(1).name).nil?, "Expected to find #{DmsfFile.find(1).name} in return data"
  end

end
