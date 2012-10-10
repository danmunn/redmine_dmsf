require File.dirname(__FILE__) + '/../../test_helper'
class WebdavTest < Test::UnitTest

  #Testing the base module Webdav

  context "Module Webdav" do
    context "Method start_module" do
      should "require a string input (module name)" do
        assert_raise(ArgumentError) do
          Webdav.start_module
        end
      end

      should "Convert string to const when string provided" do
        begin
        Module.expects(:const_get).with('Dmsf').returns(Dmsf)
        Webdav.start_module('Dmsf')
        rescue
        end
      end

      should "throw InvalidWebdavModule if not an instance of Webdav::Base" do
        assert_raise(Webdav::InvalidWebdavModule) do
          Webdav.start_module('Dmsf::Lock')
        end
      end

      should "Execute Dmsf::None when provided with non-existant class/module" do
        m = Webdav.start_module('Webdav::I::Do::Not::Exist')
        assert m.is_a?(Webdav::None)
      end

      should "return an instance of Webdav::Base (or derivative)" do
        assert Webdav.start_module(Webdav::None).kind_of?(Webdav::Base)
      end
    end
  end

end