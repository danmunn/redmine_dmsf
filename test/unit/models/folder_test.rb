require File.dirname(__FILE__) + '/../../test_helper'

module Dmsf
  class FolderTest < Test::UnitTest


    #We need to check a link the model creates to a non-existant user and project
    fixtures :projects, :users

    context "Object declaration" do

      should "utilise awesome_nested_set" do
        assert Dmsf::Folder.include?(CollectiveIdea::Acts::NestedSet::Model)
      end

      should "utilise dmsf_entity database table" do
        assert_equal Dmsf::Entity.table_name, Dmsf::Folder.table_name
      end

      should "extend Dmsf::Entity" do
        assert_equal Dmsf::Folder.superclass, Dmsf::Entity
      end

      should "be of type Dmsf::Folder" do
        entity = Dmsf::Folder.new
        assert_equal "Dmsf::Folder", entity.type
      end
    end

    context "Dmsf::Folder" do
      setup do
        @entity = Dmsf::Folder.new  :parent_id    => nil,
                                    :title        => 'Folder',
                                    :description  => '',
                                    :owner_id     => 1,
                                    :project_id   => 1,
                                    :notification => false,
                                    :deleted      => false
      end
    end

  end
end