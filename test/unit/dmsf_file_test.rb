require "test/unit"

class DmsfFileTest < DmsfEntityTest

  context "Object declaration" do
    should "extend Dmsf::Entity" do
      Dmsf::File.superclass.is_a?(Dmsf::Entity)
    end

    should "be of type Dmsf::File" do
      entity = Dmsf::File.new
      assert_equal "Dmsf::File", entity.type
    end
  end
end