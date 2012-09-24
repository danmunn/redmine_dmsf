module Dmsf
  class AuditTest < Test::UnitTest
    context "Dmsf::Audit" do
      should "be a module" do
        assert Dmsf::Audit.instance_of?(Module)
      end
    end
  end
end