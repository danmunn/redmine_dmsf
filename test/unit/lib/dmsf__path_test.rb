require File.dirname(__FILE__) + '/../../test_helper'
module Dmsf
  class PathTest < Test::UnitTest

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

      context 'method is_valid?' do
        should 'return true if path hierarchy is correct' do
          path = Dmsf::Path.new
          l1 = Dmsf::Folder.new(:title => 'Root folder')
          l1.id = 1

          l2 =  Dmsf::Folder.new(:title => 'Child folder', :parent_id => 1)
          l2.id = 2

          l3 = Dmsf::File.new(:title => 'test.jpg', :parent_id => 2)
          l3.id = 3

          path.push l1, l2, l3
          assert path.is_valid?
        end

        should 'return false if path hierarchy is not correct' do
          path = Dmsf::Path.new
          l1 = Dmsf::Folder.new(:title => 'Root folder')
          l1.id = 1

          l2 = Dmsf::File.new(:title => 'test.jpg', :parent_id => 2)
          l2.id = 3

          path.push l1, l2

          assert !path.is_valid?
        end
      end

      context "static method find" do
        setup do
          Dmsf::Folder.create! :title => 'Other',
                               :description => 'Bogus data',
                               :owner_id => 1,
                               :project_id => 1
          entity = Dmsf::Folder.create!(:title => 'Root',
                                        :description => '',
                                        :owner_id => 1,
                                        :project_id => 1)
          f1 = Dmsf::File.create! :title => 'test.file',
                                  :description => '',
                                  :parent_id => entity.id,
                                  :owner_id => 1,
                                  :project_id => 1
          f2 = Dmsf::File.create! :title => 'test.test',
                                  :description => '',
                                  :parent_id => entity.id,
                                  :owner_id => 1,
                                  :project_id => 1

          f1.stubs(:revisions).returns(stub(:visible => [Dmsf::Revision.new(:title => 'test.file', :deleted => false)]))
          f2.stubs(:revisions).returns(stub(:visible => [Dmsf::Revision.new(:title => 'test.test', :deleted => false)]))
        end
        teardown do
          Dmsf::Entity.delete_all
        end

        should "return nil when / is not present" do
          path = Dmsf::Path.find('Root', 1)
          assert path === nil
        end

        should "return nil when nothing is found" do
          path = Dmsf::Path.find('/blah', 1)
          assert path === nil, 'Expecting Dmsf::Path to return nil'
        end

        should "return a Dmsf::Path with Dmsf::Entity items contained within" do
          path = Dmsf::Path.find('/Root/test.file', 1)
          path.each{|e|
            assert e.kind_of?(Dmsf::Entity), 'Expecting Dmsf::Path item to be Dmsf::Entity'
          }
        end

        should "be case sensitive" do
          path = Dmsf::Path.find('/root/test.file', 1)
          assert path === nil
        end

      end
    end

  end
end