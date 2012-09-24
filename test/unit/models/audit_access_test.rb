module Dmsf
  module Audit
    class BaseTest < Test::UnitTest
      context "Dmsf::Audit::Access" do
        should "extend Dmsf::Audit::Base" do
          #equal, not the same
          assert Dmsf::Audit::Access.superclass == Dmsf::Audit::Base
        end
        context "public const ACCESS_TYPE_DOWNLOAD" do
          should "return 1" do
            assert Dmsf::Audit::Access.
                       ACCESS_TYPE_DOWNLOAD == 1
          end
        end

        context "public const ACCESS_TYPE_EMAIL" do
          should "return 2" do
            assert Dmsf::Audit::Access.
                       ACCESS_TYPE_EMAIL == 2
          end
        end
      end
    end
  end
end