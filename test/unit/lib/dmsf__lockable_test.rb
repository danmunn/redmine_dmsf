require File.dirname(__FILE__) + '/../../test_helper'
module Dmsf
  class LockableTest < Test::UnitTest
    context "Dmsf::Lockable" do
      context "Exception type ResourceLocked" do
        should "Inherit IOError" do
          assert_equal Dmsf::Lockable::ResourceLocked.superclass, IOError
        end
      end
      context "Exception type ResourceParentLocked" do
        should "Inherit IOError" do
          assert_equal Dmsf::Lockable::ResourceParentLocked.superclass, IOError
        end
      end
      context "Exception type ResourceNotLocked" do
        should "Inherit RuntimeError" do
          assert_equal Dmsf::Lockable::ResourceNotLocked.superclass, RuntimeError
        end
      end
      context "Exception type LockNotOwnedByPrincipal" do
        should "Inherit SecurityError" do
          assert_equal Dmsf::Lockable::LockNotOwnedByPrincipal.superclass, SecurityError
        end
      end
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
        setup do
          return_item = Dmsf::File.new
          return_item.stubs(:locks).returns([Dmsf::Lock.new])
          @item = return_item
          @item.stubs(:tree_with_locks).returns([return_item])
        end
        context 'Method tree_with_locks' do
          should 'Get contents of hierarchy' do
            @item.unstub(:tree_with_locks)
            expectation = mock()
            expectation.expects(:includes).with(:locks).returns([@item])
            @item.expects(:self_and_ancestors).returns(expectation)
            @item.tree_with_locks
          end
        end

        context 'Method effective_locks' do
          should 'call tree_with_locks with additional where clause' do
            #We need to mock not stub this
            @item.unstub(:tree_with_locks)
            expectation = mock()
            expectation.expects(:where).returns([])
            @item.expects(:tree_with_locks).returns(expectation)
            @item.effective_locks
          end

          should "return an array of locks at lowest effective point in hierarchy" do
            @item.unstub(:tree_with_locks)
            expectation = mock()
            expectation.stubs(:where).returns([@item])
            @item.stubs(:tree_with_locks).returns(expectation)
            value = @item.effective_locks
            assert value.is_a?(Array)
            assert !value.empty?
          end

          should "return an empty array when no locks exist on item" do
            @item.unstub(:tree_with_locks)
            expectation = mock()
            expectation.stubs(:where).returns([])
            @item.stubs(:tree_with_locks).returns(expectation)
            value = @item.effective_locks
            assert value.is_a?(Array)
            assert value.empty?
          end

        end

        context 'Method locked?' do
          should 'utilise method effective_locks' do
            @item.expects(:effective_locks).returns([])
            @item.locked?
          end
          should 'return true when valid lock exists on item' do
            @item.stubs(:effective_locks).returns([Dmsf::Lock.new])
            assert @item.locked?
          end
          should 'return false when no locks are available to item' do
            @item.stubs(:effective_locks).returns([])
            assert !@item.locked?
          end
        end

        context 'Method unlock!' do
          fixtures :users

          should 'raise ResourceNotLocked when not locked' do
            assert_raise(Dmsf::Lockable::ResourceNotLocked) do
              @item.stubs(:locked?).returns(false)
              @item.unlock!
            end
          end

          should 'raise ResourceParentLocked when item in hierarchy above principal is locked' do
            assert_raise(Dmsf::Lockable::ResourceParentLocked) do
              @item.stubs(:effective_locks).returns([Dmsf::Lock.new(:entity_id => 1)])
              @item.unlock!
            end
          end

          should 'raise LockNotOwnedByPrincipal when called with different id to owner' do
            assert_raise(Dmsf::Lockable::LockNotOwnedByPrincipal) do
              @item.stubs(:effective_locks).returns([Dmsf::Lock.new()])
              @item.unlock!() #Lock does not hold an id
            end
          end

          should 'delete the lock when all criteria are met' do
            expectation = mock()
            expectation.expects(:delete).returns(true)
            expectation.stubs(:entity_id).returns(@item.id)
            expectation.stubs(:user_id).returns(1)
            @item.stubs(:effective_locks).returns([expectation])
            @item.unlock!(User.find(1)) #Lock does not hold an id
          end

        end
      end

    end
  end
end