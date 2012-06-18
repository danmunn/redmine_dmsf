module RedmineDmsf
  module Test
    class TestCase < ActionController::TestCase

      # Allow us to override the fixtures method to implement fixtures for our plugin.
      # Ultimately it allows for better integration without blowing redmine fixtures up,
      # and allowing us to suppliment redmine fixtures if we need to.
      def self.fixtures(*table_names)
        dir = File.join( File.dirname(__FILE__), "../../../test/fixtures" )
        table_names.each{|x|
          ActiveRecord::Fixtures.create_fixtures(dir, x) if File.exist?(dir + "/" + x.to_s + ".yml")
        }
        super(table_names)
      end
      
      def setup
        @request = ActionController::TestRequest.new
        @response = ActionController::TestResponse.new
      end
      
    end
  end
end