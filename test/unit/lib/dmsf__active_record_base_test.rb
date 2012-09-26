require File.dirname(__FILE__) + '/../../test_helper'
module Dmsf
  class ActiveRecordBaseTest < Test::UnitTest
    context "Dmsf::ActiveRecordBase" do
      should "force dmsf_ table prefix" do
        assert_equal "dmsf_", Dmsf::ActiveRecordBase.table_name_prefix
      end

      should "be an abstract class" do
        assert Dmsf::ActiveRecordBase.abstract_class?
      end
    end
  end
end