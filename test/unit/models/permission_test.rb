require File.dirname(__FILE__) + '/../../test_helper'

module Dmsf
  class PermissionTest < Test::UnitTest

    should belong_to(:entity)

    context "Dmsf::Permission" do
      should 'utilise the table dmsf_permissions' do
        assert_equal 'dmsf_permissions', Dmsf::Permission.table_name
      end

      context 'Scope perm' do
        should 'make use of a bitwise operator in query' do
          sql = Dmsf::Permission.perm(Dmsf::Permission.READ).to_sql
          assert sql.match(/permission ~ 1 = 1/)
        end
      end

      context 'Constants' do
        should 'Contain READ with integer value 1' do
          assert_equal Dmsf::Permission.READ, 1
        end
        should 'Contain WRITE with integer value 2' do
          assert_equal Dmsf::Permission.WRITE, 2
        end
        should 'Contain MODIFY with integer value 4' do
          assert_equal Dmsf::Permission.MODIFY, 4
        end
        should 'Contain DELETE with integer value 8' do
          assert_equal Dmsf::Permission.DELETE, 8
        end
        should 'Contain ASSIGN with integer value 16' do
          assert_equal Dmsf::Permission.ASSIGN, 16
        end
      end

    end

  end
end