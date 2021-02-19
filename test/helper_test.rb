# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Test
    class HelperTest < ActiveSupport::TestCase

      fixtures :users, :email_addresses, :projects

      # Allow us to override the fixtures method to implement fixtures for our plugin.
      # Ultimately it allows for better integration without blowing redmine fixtures up,
      # and allowing us to suppliment redmine fixtures if we need to.
      def self.fixtures(*table_names)
        dir = File.join(File.dirname(__FILE__), 'fixtures')
        redmine_table_names = []
        table_names.each do |x|
          if File.exist?(File.join(dir, "#{x}.yml"))
            ActiveRecord::FixtureSet.create_fixtures(dir, x)
          else
            redmine_table_names << x
          end
        end
        super redmine_table_names if redmine_table_names.any?
      end

      def setup
        @jsmith = User.find 2
        @project1 = Project.find 1
        @folder1 = DmsfFolder.find 1
        Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = nil
        Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders'] = nil
      end
    end
  end
end