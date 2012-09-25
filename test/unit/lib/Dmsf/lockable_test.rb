require File.dirname(__FILE__) + '/../../../test_helper'
module Dmsf
  class LockableTest < Test::UnitTest
    context "Dmsf::Lockable" do
      context "Static method included" do
        setup do
          @m_class = stub_everything('Dmsf::Lockable.included')
          Class.any_instance.stubs(:has_many)
        end
        teardown do
          Class.any_instance.unstub(:has_many) #Lets not leave that there.
        end
        should "Invoke send on receiving class with reference to InstanceMethods" do
          @m_class.expects(:send).with(:include, Dmsf::Lockable::InstanceMethods).returns(true)
          @m_class.stubs(:include).returns(true)
          Dmsf::Lockable.included(@m_class)
        end
        should "Invoke extend on receiving class with reference to ClassMethods" do
          @m_class.expects(:extend).with(Dmsf::Lockable::ClassMethods).returns(true)
          Class.any_instance.stubs(:has_many)
          Dmsf::Lockable.included(@m_class)
        end
        should "Invoke instance method has_many with arguments" do
          Class.any_instance.unstub(:has_many)
          Class.any_instance.expects(:has_many).once().returns(true)
          Dmsf::Lockable.included(@m_class)
        end
      end

      context 'InstanceMethods' do

        context 'Method locked?' do
          should 'utilise protected method '
        end
      end

    end
  end
end