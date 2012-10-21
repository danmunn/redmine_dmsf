require File.dirname(__FILE__) + '/../../test_helper'
class WebdavDmsfStandardTest < Test::UnitTest
  context "Class Webdav::Dmsf::Standard" do
    setup do
      @obj = Webdav::Dmsf::Standard.new
    end
    should "extend Webdav::Base" do
      assert @obj.kind_of?(Webdav::Base)
    end

    context "Method rails_mount" do
      teardown do
        RedmineApp::Application.routes.unstub(:append)
      end

      should 'Append route to rails router' do
        #Do not specify criteria, as it's a complex set really ...
        RedmineApp::Application.routes.expects(:append)
        @obj.load_config({}) #We setup with no config
        @obj.rails_mount
      end

      should 'Add its middleware to stack' do
        RedmineApp::Application.middleware.expects(:insert_before)
        @obj.load_config({}) #We setup with no config
        @obj.rails_mount
      end

    end
  end

  context "Sub-class Locked" do
    should 'behave the same as Webdav::Dmsf::Standard' do
      obj = Webdav::Dmsf::Standard::Locked.new
      RedmineApp::Application.routes.expects(:append)
      RedmineApp::Application.middleware.expects(:insert_before)
      obj.load_config({})
      obj.rails_mount
    end
  end
end