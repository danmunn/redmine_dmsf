require File.dirname(__FILE__) + '/../../test_helper'
module Dmsf
  class IndexingTest < Test::UnitTest
    context 'Dmsf::Indexing' do
      context 'Method getIndexer' do
        should 'return an instance of Dmsf::Indexing' do
          assert_equal Dmsf::Indexing, Dmsf::Indexing.getIndexer.class
        end
        should 'Only return one instance of Dmsf::Indexing' do
          get_1 = Dmsf::Indexing.getIndexer
          get_2 = Dmsf::Indexing.getIndexer
          assert_same get_1, get_2
        end
      end

      context "method xapian_available?" do
        should 'return boolean' do

        end
      end

    end
  end
end
