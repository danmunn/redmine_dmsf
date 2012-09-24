module Dmsf
  module Audit
    class BaseTest < Test::UnitTest
      context "Dmsf::Audit::Base" do
        should belong_to(:relation)
        should belong_to(:user)

        context "attribute meta" do
          should "be an OpenStruct" do
            a = Dmsf::Audit::Base.new
            assert a.meta.instance_of?(OpenStruct)
          end
        end

      end
    end
  end
end