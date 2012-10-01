require File.dirname(__FILE__) + '/../../test_helper'
module Dmsf
  class Acl_test < Test::UnitTest
    context 'Dmsf::Acl' do
      context 'Method initialise' do
        should 'require an argument' do
          assert_raise(ArgumentError) do
            Dmsf::Acl.new
          end
        end

        should 'raise ArgumentError if argument is not Dmsf::Entity' do
          assert_raise(ArgumentError) do
            Dmsf::Acl.new("String")
          end
        end
      end

      context "Method visible_siblings" do
        should 'set user to User.current if not set' do
          User.expects(:current).returns(User.find(6))
          file = Dmsf::File.new
          file.stubs(:siblings).returns([])
          file.Acl.visible_siblings
        end

        should 'retrieve the current hierarchy' do
          file = Dmsf::File.new :parent_id => 1
          file.expects(:ancestors).returns([])
          file.stubs(:siblings).returns([])
          file.Acl.visible_siblings
        end

        should 'retrieve siblings at current level' do
          file = Dmsf::File.new
          file.stubs(:ancestors).returns([])
          file.expects(:siblings).returns([])
          file.Acl.visible_siblings
        end

        should 'Execute load_individual_permission with join of ancestors and siblings' do
          file = Dmsf::File.new :parent_id => 1
          parent = Dmsf::Folder.new
          parent.id = 1
          file.stubs(:ancestors).returns([parent])
          file.stubs(:siblings).returns([])
          file.Acl.expects(:load_individual_permission).with([parent] + [], 1, User.current).returns([])
          file.Acl.visible_siblings
        end
      end

      context 'Method visible?' do
        should 'retrieve its hierarchy' do
          file = Dmsf::File.new
          file.expects(:self_and_ancestors).returns([file])
          file.Acl.visible?
        end

        should 'Load permissions based on hierarchy' do
          file = Dmsf::File.new
          file.stubs(:self_and_ancestors).returns([file])
          file.Acl.expects(:load_individual_permission).with([file], 1, User.current).returns([])
          file.Acl.visible?
        end

        should 'return false if a negative permission is set on object' do
          file = Dmsf::File.new
          file.stubs(:self_and_ancestors).returns([file])
          file.Acl.stubs(:load_individual_permission).returns([Dmsf::Permission.new(:user_id => User.current.id, :prevent => true, :permission => 1)])
          file.Acl.visible?
        end
      end

      context 'Method permissions_for' do
        should 'retrieve its hierarchy' do
          file = Dmsf::File.new
          file.expects(:self_and_ancestors).returns([file])
          file.Acl.permissions_for
        end

        should 'Load permissions based on hierarchy' do
          file = Dmsf::File.new
          file.stubs(:self_and_ancestors).returns([file])
          file.Acl.expects(:load_all_permissions).with([file], User.current).returns([])
          file.Acl.permissions_for
        end

        should 'return a hash with all true by default' do
          file = Dmsf::File.new
          file.stubs(:self_and_ancestors).returns([file])
          assert_equal file.Acl.permissions_for, {:read => true, :write => true,
                                                  :modify => true, :delete => true,
                                                  :perms => true}

        end

        should 'return a hash with read set false when a prevent exists on object' do
          file = Dmsf::File.new
          file.stubs(:self_and_ancestors).returns([file])
          file.Acl.stubs(:load_all_permissions).returns([
                                                            Dmsf::Permission.new(
                                                              :user_id => User.current.id,
                                                              :prevent => true,
                                                              :permission => 1
                                                            )
                                                        ])
          assert_equal file.Acl.permissions_for, {:read => false, :write => true,
                                                  :modify => true, :delete => true,
                                                  :perms => true}
        end
      end


      context "Method visible_children" do
        should "return [] if current object is not Dmsf::File" do
          file = Dmsf::File.new
          assert_equal [], file.Acl.visible_children
        end

        should 'retrieve its hierarchy' do
          folder = Dmsf::Folder.new
          folder.expects(:self_and_ancestors).returns([folder])
          folder.Acl.visible_children
        end

        should 'retrieve child entities' do
          folder = Dmsf::Folder.new
          folder.stubs(:self_and_ancestors).returns([folder])
          folder.expects(:children).returns([Dmsf::File.new])
          folder.Acl.visible_children
        end

        should 'Load permissions based on hierarchy' do
          folder = Dmsf::Folder.new
          m_file = Dmsf::File.new(:title => 'Spectacular')
          folder.stubs(:self_and_ancestors).returns([folder])
          folder.stubs(:children).returns([m_file])
          folder.Acl.expects(:load_individual_permission).with([folder] + [m_file], 1, User.current).returns([])
          folder.Acl.visible_children
        end

        should 'return all children if no permissions exist' do
          folder = Dmsf::Folder.new
          m_file = Dmsf::File.new(:title => 'Spectacular')
          folder.stubs(:self_and_ancestors).returns([folder])
          folder.stubs(:children).returns([m_file])
          folder.Acl.stubs(:load_individual_permission).returns([])
          assert_equal folder.Acl.visible_children, [m_file]
        end
      end

      context "Extended logic verification" do
        fixtures :users
        should 'Process user logic with more weight than role logic' do
          user = User.find(1)
          #Role ID 2 prevent read/write
          r_perm = Dmsf::Permission.new(:role_id => 2, :prevent => true, :permission => 3)
          #User ID 1 permit read
          u_perm = Dmsf::Permission.new(:user_id => 1, :prevent => false, :permission => 1)
          #Should have outcome: read but not write
          file = Dmsf::File.new
          file.stubs(:self_and_ancestors).returns([file])
          file.Acl.stubs(:load_all_permissions).returns([r_perm, u_perm])
          assert_equal file.Acl.permissions_for(user), {:read => true, :write => false,
                                                        :modify => true, :delete => true,
                                                        :perms => true}
        end

        should 'Inherit Permissions' do
          user = User.find(1)
          u_perm = Dmsf::Permission.new(:user_id => 1, :prevent => true, :permission => 2, :entity_id => 1)
          file = Dmsf::File.new{parent_id = 1}; file.id = 2
          folder = Dmsf::Folder.new; folder.id = 1
          file.stubs(:self_and_ancestors).returns([folder, file])
          file.Acl.stubs(:load_all_permissions).returns([u_perm])
          assert_equal file.Acl.permissions_for(user), {:read => true, :write => false,
                                                        :modify => true, :delete => true,
                                                        :perms => true}
        end
      end
    end
  end
end