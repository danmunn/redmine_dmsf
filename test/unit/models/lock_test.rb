require File.dirname(__FILE__) + '/../../test_helper'

module Dmsf
  class LockTest < Test::UnitTest
    should belong_to :entity
    should belong_to :user

    context "Dmsf::Lock" do
      context "method expired?" do

        should "return false if 'Now' is less than expiry" do
          lock = Dmsf::Lock.new(:expires_at => 3.minutes.from_now)
          assert !lock.expired?
        end

        should "return true if 'Now' is greater than expiry" do
          lock = Dmsf::Lock.new(:expires_at => 3.minutes.ago)
          assert lock.expired?
        end

        should "return true if 'Now' equals expiry" do
          #In theory if a lock is meant to expire at 10:00, at 10:00:35 you don't
          #want lock still active, do you?
          lock = Dmsf::Lock.new(:expires_at => Time.now)
          assert lock.expired?
        end
      end

      context "method generate_uuid" do

        should "Use the UUID toolset to generate a timestamp based UUID" do
          UUIDTools::UUID.expects(:timestamp_create).returns('b0825020-03cf-11e2-a1b3-005056c00001')
          lock = Dmsf::Lock.new
          lock.send(:generate_uuid)
        end
        should "set the uuid column" do
          lock = Dmsf::Lock.new
          assert lock.uuid.nil?
          lock.send(:generate_uuid)
          assert !lock.uuid.nil?
        end
      end
      context "before_create" do
        should "call Dmsf::Lock.generate_uuid" do
          lock = Dmsf::Lock.new
          lock.expects(:generate_uuid)

          #There has to be a cleaner way of testing the callback without
          #running a blind execute on it :/
          lock.send(:_run_create_callbacks)
        end
      end


      context "Dmsf::Lock.find" do
        setup do
          @lock = Dmsf::Lock.create! :entity_id  => 1,
                                     :user_id    => 1,
                                     :lock_type  => 0,
                                     :lock_scope => 0,
                                     :uuid       => UUIDTools::UUID.timestamp_create().to_s,
                                     :expires_at => 3.minutes.from_now
        end
        teardown do
          Dmsf::Lock.delete_all
        end
        should "Find a lock by its ID" do
          lock = Dmsf::Lock.find(@lock.id)
          assert !lock.nil?
          assert lock === @lock
        end

        should "Find a lock by its UUID" do
          lock = Dmsf::Lock.find(@lock.uuid)
          assert !lock.nil?
          assert lock === @lock
        end

        should "raise an exception if hash is not found" do
           assert_raise(ActiveRecord::RecordNotFound) do
             Dmsf::Lock.find('abc123') #This should not be found
           end
        end
      end
      context "Static method delete_expired" do
        should "depend on the expired scope" do
          #Prepare mock object
          model = mock()
          model.expects(:delete_all)

          #Stub the expired scope to return our model
          Dmsf::Lock.expects(:expired).returns(model)

          Dmsf::Lock.delete_expired
        end
      end
    end

  end
end