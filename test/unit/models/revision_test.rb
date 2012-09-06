require File.dirname(__FILE__) + '/../../test_helper'

module Dmsf
  class RevisionTest < Test::UnitTest

    should belong_to(:file)
    should belong_to(:source_revision)
    should belong_to(:owner)
    should belong_to(:deleted_by)
    should belong_to(:project)

    context "Dmsf::Revision" do

    end

  end
end