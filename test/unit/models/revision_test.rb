require File.dirname(__FILE__) + '/../../test_helper'

module Dmsf
  class RevisionTest < Test::UnitTest

    should belong_to(:file)
    should belong_to(:source_revision)
    should belong_to(:owner)
    should belong_to(:deleted_by)
    should belong_to(:project)
    should have_many(:accesses)

    context "Dmsf::Revision" do
      context "named scope :visible" do
        should "exist" do
          assert Dmsf::Revision.respond_to?(:visible)
        end
        should "return items not deleted" do
          options = {:deleted => false}
          assert helper_hash_compare(
                     options,
                     Dmsf::Revision.visible.where_values_hash)
        end
      end

      context "named scope :deleted" do
        should "exist" do
          assert Dmsf::Revision.respond_to?(:deleted)
        end

        should "return items deleted" do
          options = {:deleted => true}
          assert helper_hash_compare(
                     options,
                     Dmsf::Revision.deleted.where_values_hash)
          #assert_equal options,
                       #Dmsf::Revision.deleted.where_values_hash
        end
      end
    end


    def helper_hash_compare(hash1, hash2)
      hash1.each_pair{|key,value|
        return false unless hash2.has_key?(key)
        return false unless hash2[key] == value
      }
      true
    end
  end
end