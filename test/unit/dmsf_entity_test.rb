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
      @entity = Dmsf::Entity.new  :collection   => false,
                                  :parent_id    => nil,
                                  :title        => 'Folder',
                                  :description  => '',
                                  :owner_id     => 1,
                                  :project_id   => 1,
                                  :notification => false,
                                  :deleted      => false
    end

    context "without fixtures" do
      should "accept and return valid arguments" do
        assert_equal false, @entity.collection
        assert_equal 'Folder', @entity.title
      end

    end
    should "return an owning user object" do
      @entity.owner_id = 1
      assert_kind_of User, @entity.owner
    end

    should "return an owning project object" do
      assert_kind_of Project, @entity.project
    end

    should "return a deleted_by user object or nil when not found" do
      @entity.deleted_by_id = 1
      assert_kind_of User, @entity.deleted_by

      @entity.deleted_by_id = 0 #We know from the fixtures that user id=0 does not exist.
      assert_nil @entity.deleted_by
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
  end
end