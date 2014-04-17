# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2013   Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Load the normal Rails helper
#require File.expand_path("#{Rails.root}/test/test_helper")

# Use fixtures from redmine
#ActiveSupport::TestCase.fixture_path = "#{Rails.root}/test/fixtures"

module RedmineDmsf
  module Test
    class UnitTest < ActiveSupport::TestCase

      # Allow us to override the fixtures method to implement fixtures for our plugin.
      # Ultimately it allows for better integration without blowing redmine fixtures up,
      # and allowing us to suppliment redmine fixtures if we need to.
      def self.fixtures(*table_names)        
        dir = File.expand_path('../../../../test/fixtures', __FILE__)        
        table_names.each do |x|
          if File.exist?("#{dir}/#{x}.yml")
            ActiveRecord::Fixtures.create_fixtures(dir, x)           
          end
        end
        super(table_names)
      end
      
    end
  end
end
