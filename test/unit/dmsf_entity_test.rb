require File.dirname(__FILE__) + '/../test_helper'

class DmsfEntityTest < Test::UnitTest

  #We need to check a link the model creates to a non-existant user and project
  fixtures :projects, :users

  test "Model utilises awesome_nested_set" do
    assert Dmsf::Entity.include?(CollectiveIdea::Acts::NestedSet::Model)
  end

  test "Model utilises dmsf_entity database table" do
    assert_equal "#{Dmsf::Entity.table_name_prefix}entities#{Dmsf::Entity.table_name_suffix}", Dmsf::Entity.table_name
  end
  
  context "Dmsf::Entity" do
    setup do
      @entity = Dmsf::Entity.new  :parent_id    => nil,
                                  :title        => 'Folder',
                                  :description  => '',
                                  :owner_id     => 1,
                                  :project_id   => 1,
                                  :notification => false,
                                  :deleted      => false
    end

    context "without fixtures" do
      should "accept and return valid arguments" do
        assert_equal 'Folder', @entity.title
      end

    end

    context "Rules: Deleted" do
      should "return a deleted_by user object or nil when not found" do
        @entity.deleted_by_id = 1
        assert_kind_of User, @entity.deleted_by

        @entity.deleted_by_id = 0 #We know from the fixtures that user id=0 does not exist.
        assert_nil @entity.deleted_by
      end
      
      should "not be valid if object is flagged deleted but holds deleted_by data" do
        @entity.deleted = false
        @entity.deleted_by_id = 1
        assert @entity.invalid?
      end
    end

    context "Field: title" do
      should "require a non-nil value" do
        @entity.title = nil
        assert_nil @entity.title
        assert !@entity.valid?
      end

      should "prevent usage of forbidden path characters" do
        @entity.title = "#!/asd?!test";
        assert !@entity.valid?, 'Entity should not be valid'
      end

      should "permit a simple filename" do
        @entity.title = "test123.jpg"
        assert @entity.valid?, 'Entity should be valid'
      end
    end
    
    context "Field: project" do
      
      should "require a non-nil value" do
        @entity.project = nil
        assert_nil @entity.project
        assert @entity.invalid?
      end
      
      should "return an owning project object" do
        assert_kind_of Project, @entity.project
      end
      
      should "return nil when referenced project does not exist" do
        @entity.project_id = 0
        assert_nil @entity.project
      end
    end
    
    context "Field: owner" do
      
      should "require a non-nil value" do
        @entity.owner = nil
        assert_nil @entity.owner
        assert @entity.invalid?
      end
      
      should "return an owning user object" do
        assert_kind_of User, @entity.owner
      end
      
      should "return nil when referenced user does not exist" do
        @entity.owner_id = 0
        assert_nil @entity.owner
      end
    end

    context "Path information" do
      teardown do
        Dmsf::Entity.delete_all
      end

      setup do
        @entity = Dmsf::Entity.create!  :title        => 'Folder1',
                                        :deleted      => false,
                                        :description  => '',
                                        :owner_id     => 1,
                                        :project_id   => 1
      end

      context "retrieval" do
        should "return an array with self in for root level item when calling path" do
          path = @entity.path
          assert path.kind_of?(Dmsf::Path)
          assert_equal 1, path.length
          assert_equal 'Folder1', path[0].title
        end

        should "return a string with self in for root level item when calling path_to_s" do
          path = @entity.path.to_s
          assert path.is_a?(String);
          assert_equal 'Folder1', path
        end

        should "return a multi-element array for a non-root object" do
          child = Dmsf::Entity.new  :title        => 'Folder2',
                                    :deleted      => false,
                                    :description  => '',
                                    :parent_id    => @entity.id,
                                    :owner_id     => 1,
                                    :project_id   => 1
          path = child.path
          assert path.kind_of?(Dmsf::Path)
          assert_equal 2, path.length
          assert_equal 'Folder2', path[1].title
        end

      end
    end

    context "Item duplication" do

      #The tests in this will create test data, it'll
      #be nice to clean that up
      teardown do
        Dmsf::Entity.delete_all
      end

      #satisfied by Dmsf::Entity.without_self
      #This test fails under circumstances where checking a nil entry (unsaved)
      #is checked for validity against existing data, awesome_nested set makes a
      # != null query, which is invalid should be IS NOT NULL.

      should "generate appropriate query based on primary key being nil (or not)" do
        root = Dmsf::Entity.new :title        => 'Folder1',
                                :deleted      => false,
                                :description  => '',
                                :owner_id     => 1,
                                :project_id   => 1
        query = root.without_self(Dmsf::Entity)
        assert_match /IS NOT/, query.to_sql

        root.id = 1
        query = root.without_self(Dmsf::Entity)
        assert_match /!=/, query.to_sql
      end

      should "Prevent same-named items at the same level from existing" do
        Dmsf::Entity.delete_all
        #Create a root level node
        #This will actually be a Dmsf::Folder
        root = Dmsf::Entity.create! :title        => 'Folder1',
                                    :deleted      => false,
                                    :description  => '',
                                    :owner_id     => 1,
                                    :project_id   => 1

        #Create a leaf - this will actually be a Dmsf::File
        test_obj = Dmsf::Entity.create! :title    => 'Test.jpg',
                                    :deleted      => false,
                                    :description  => '',
                                    :owner_id     => 1,
                                    :project_id   => 1
        root.children << test_obj
        @entity.title = "Test.jpg"
        root.children << @entity
        assert_equal root.children.count, 1
        assert @entity.invalid?
      end
    end



  end
end