require File.expand_path('../../test_helper', __FILE__)

class DmsfWebdavPostTest < RedmineDmsf::Test::IntegrationTest

  fixtures :users, :enabled_modules

  def setup
    @headers = credentials('admin')
    super
  end

  def teardown
    @headers = nil
  end

  #Test that any post request is authenticated
  def test_post_request_authenticated
    post "/dmsf/webdav/"
    assert_response 401 #401 Unauthorized
  end

  #Test post is not implimented
  def test_post_not_implemented
    post "/dmsf/webdav/", nil, @headers
    assert_response 501 #501 Not Implemented
  end
end
