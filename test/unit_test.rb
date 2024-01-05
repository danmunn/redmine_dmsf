# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
#  Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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
    # Unit test
    class UnitTest < ActiveSupport::TestCase
      fixtures :users, :email_addresses, :projects, :roles, :members, :member_roles

      def setup
        @admin = User.find_by(login: 'admin')
        @jsmith = User.find_by(login: 'jsmith')
        @dlopper = User.find_by(login: 'dlopper')
        @manager_role = Role.find_by(name: 'Manager')
        @developer_role = Role.find_by(name: 'Developer')
        [@manager_role, @developer_role].each do |role|
          role.add_permission! :view_dmsf_folders
          role.add_permission! :folder_manipulation
          role.add_permission! :view_dmsf_files
          role.add_permission! :file_manipulation
          role.add_permission! :file_delete
        end
        @project1 = Project.find 1
        @project2 = Project.find 2
        @project3 = Project.find 3
        @project5 = Project.find 5
        [@project1, @project2, @project3, @project5].each do |project|
          project.enable_module! :dmsf
        end
        @file1 = DmsfFile.find 1
        @file2 = DmsfFile.find 2
        @file4 = DmsfFile.find 4
        @file5 = DmsfFile.find 5
        @file7 = DmsfFile.find 7
        @file8 = DmsfFile.find 8
        @file11 = DmsfFile.find 11
        @file13 = DmsfFile.find 13
        @folder_link1 = DmsfLink.find 1
        @file_link2 = DmsfLink.find 2
        @file_link7 = DmsfLink.find 7
        @folder1 = DmsfFolder.find 1
        @folder2 = DmsfFolder.find 2
        @folder6 = DmsfFolder.find 6
        @folder7 = DmsfFolder.find 7
        @folder8 = DmsfFolder.find 8
        Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.join('files', ['dmsf'])
        FileUtils.cp_r File.join(File.expand_path('../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
        User.current = nil
      end

      def teardown
        # Delete our tmp folder
        FileUtils.rm_rf DmsfFile.storage_path
      rescue StandardError => e
        Rails.logger.error e.message
      end

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

      protected

      def last_email
        ActionMailer::Base.deliveries.last
      end

      def text_part(email)
        email.parts.detect { |part| part.content_type.include?('text/plain') }
      end

      def html_part(email)
        email.parts.detect { |part| part.content_type.include?('text/html') }
      end
    end
  end
end
