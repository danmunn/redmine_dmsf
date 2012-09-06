require File.dirname(__FILE__) + '/../../test_helper'

module Dmsf
  class FileTest < Test::UnitTest
    #We need to check a link the model creates to a non-existant user and project
    fixtures :projects, :users

    context "Object declaration" do

      should have_many(:revisions)

      should "Utilise awesome_nested_set" do
        assert Dmsf::File.include?(CollectiveIdea::Acts::NestedSet::Model)
      end

      should "Utilise dmsf_entity database table" do
        assert_equal Dmsf::Entity.table_name, Dmsf::File.table_name
      end

      should "extend Dmsf::Entity" do
        assert_equal Dmsf::Folder.superclass, Dmsf::Entity
      end

      should "be of type Dmsf::File" do
        entity = Dmsf::File.new
        assert_equal "Dmsf::File", entity.type
      end

    end
  end
end