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

    class IntegrationTest < Redmine::IntegrationTest

      self.fixtures :users, :email_addresses, :projects, :roles, :members, :member_roles

      def setup
        @admin = credentials('admin', 'admin')
        @admin_user = User.find_by(login: 'admin')
        @jsmith = credentials('jsmith', 'jsmith')
        @jsmith_user = User.find_by(login: 'jsmith')
        @someone = credentials('someone', 'foo')
        @anonymous = credentials('')
        @project1 = Project.find 1
        @project2 = Project.find 2
        @project3 = Project.find 3
        [@project1, @project2, @project3].each do |project|
          project.enable_module! :dmsf
        end
        @file1 = DmsfFile.find 1
        @file2 = DmsfFile.find 2
        @file9 = DmsfFile.find 9
        @file10 = DmsfFile.find 10
        @file12 = DmsfFile.find 12
        @folder1 = DmsfFolder.find 1
        @folder2 = DmsfFolder.find 2
        @folder3 = DmsfFolder.find 3
        @folder6 = DmsfFolder.find 6
        @folder7 = DmsfFolder.find 7
        @folder10 = DmsfFolder.find 10
        @role = Role.find_by(name: 'Manager')
        @role.add_permission! :view_dmsf_folders
        @role.add_permission! :folder_manipulation
        @role.add_permission! :view_dmsf_files
        @role.add_permission! :file_manipulation
        @role.add_permission! :file_delete
        Setting.plugin_redmine_dmsf['dmsf_webdav'] = '1'
        Setting.plugin_redmine_dmsf['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
        Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = nil
        Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders'] = nil
        Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.join(%w(files dmsf))
        FileUtils.cp_r File.join(File.expand_path('../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
        User.current = nil
      end

      def teardown
        # Delete our tmp folder
        begin
          FileUtils.rm_rf DmsfFile.storage_path
        rescue => e
          Rails.logger.error e.message
        end
      end

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

      def check_headers_exist
        assert !(response.headers.nil? || response.headers.empty?),
               'Head returned without headers' # Headers exist?
        values = {}
        values[:etag] = { optional: true, content: response.headers['Etag'] }
        values[:content_type] = response.headers['Content-Type']
        values[:last_modified] = { optional: true, content: response.headers['Last-Modified'] }
        single_optional = false
        values.each do |key,val|
          if val.is_a?(Hash)
            if val[:optional].nil? || !val[:optional]
              assert(!(val[:content].nil? || val[:content].empty?), "Expected header #{key} was empty." ) if single_optional
            else
              single_optional = true
            end
          else
            assert !(val.nil? || val.empty?), "Expected header #{key} was empty."
          end
        end
      end

      def check_headers_dont_exist
        assert !(response.headers.nil? || response.headers.empty?), 'Head returned without headers' # Headers exist?
        values = {}
        values[:etag] = response.headers['Etag']
        values[:last_modified] = response.headers['Last-Modified']
        values.each do |key,val|
          assert (val.nil? || val.empty?), "Expected header #{key} should be empty."
        end
      end

    end

  end
end