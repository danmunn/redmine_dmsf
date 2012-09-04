require File.dirname(__FILE__) + '/../test_helper'
class DmsfPathTest < Test::UnitTest

  context "Dmsf::Path" do
    should "extend the array object" do
      assert_equal Dmsf::Path.superclass, Array
    end

    context "method <<" do
      should "raise error if non Dmsf::Entity object is added" do
        path = Dmsf::Path.new
        assert_raise(ArgumentError){ path << 'a' }
      end

      should "not raise exception if Dmsf::Entity object is added" do
        path = Dmsf::Path.new
        assert_nothing_raised {path << Dmsf::Entity.new }
        assert_equal 1, path.length
      end

    end

    context "method push" do

      should "raise error if non Dmsf::Entity object is added" do
        path = Dmsf::Path.new
        assert_raise(ArgumentError){ path.push 'a' }
      end

      should "not raise exception if Dmsf::Entity object is added" do
        path = Dmsf::Path.new
        assert_nothing_raised {path.push Dmsf::Entity.new }
        assert_equal 1, path.length
      end

      should "push like an array" do
        path = Dmsf::Path.new
        assert path.push Dmsf::Entity.new, Dmsf::Entity.new, Dmsf::Entity.new
        assert_equal 3, path.length
      end

    end

    context "method to_s" do
      should "exist" do
        path = Dmsf::Path.new
        assert path.respond_to?(:to_s)
      end

      should "return a string when collection is empty" do
        path = Dmsf::Path.new
        assert path.to_s.kind_of?(String)
      end

      should "return an empty string when collection is empty" do
        path = Dmsf::Path.new
        assert_equal "", path.to_s
      end
    end

    context 'method is_orphan?' do
      should "return true if first items parent id is not nil" do
        path = Dmsf::Path.new
        path << Dmsf::Entity.new(:title => 'Test_orphan', :parent_id => 4)
        assert path.is_orphan?
      end

      should "return false if first items parent id is nil" do
        path = Dmsf::Path.new
        path << Dmsf::Entity.new(:title => 'Test_normal')
        assert !path.is_orphan?
      end

    end
  end

end