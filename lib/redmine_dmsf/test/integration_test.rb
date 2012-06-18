module RedmineDmsf
  module Test
    class IntegrationTest < ActionController::IntegrationTest
      def self.fixtures(*table_names)
        dir = File.join(File.dirname(__FILE__), "../../../test/fixtures" )
        modified_tables = table_names.reject{|x| !File.exist?(dir + "/" + x.to_s + ".yml") }
        ActiveRecord::Fixtures.create_fixtures(dir, modified_tables) unless modified_tables.empty?
        table_names -= modified_tables
        super(table_names-modified_tables)
        
      end
    end
  end
end
