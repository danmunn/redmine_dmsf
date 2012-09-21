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

      context "method last_revision" do
        should "exist" do
          entity = Dmsf::File.new
          assert entity.respond_to?(:last_revision)
        end

        should "return an instance of null when revision should not exist" do
          entity = Dmsf::File.new
          assert entity.last_revision.nil?
        end

        should "return an instance of Dmsf::Revision" do
          t_fil = Dmsf::File.new(:owner_id => 1,
                                 :project_id => 1,
                                 :title => 'Test.jpg')

          t_rev = Dmsf::Revision.new(:owner_id => 1,
                                     :project_id => 1,
                                     :file_id => t_fil.id,
                                     :title => 'not_here.jpg')
          m_rev = mock()
          t_fil.stubs(:revisions).returns(stub(:visible => [t_rev]))

          assert t_fil.last_revision.kind_of?(Dmsf::Revision)

        end
      end
    end
  end
end