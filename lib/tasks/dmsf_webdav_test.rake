# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

desc <<~END_DESC
  DMSF WebDAV test task
    * Create a test project with DMSF module enabled
    * Enable REST API in settings
    * Enable WebDAV in plugin's settings

  Example:
    rake redmine:dmsf_webdav_test_on RAILS_ENV="test"
    rake redmine:dmsf_webdav_test_off RAILS_ENV="test"
END_DESC

namespace :redmine do
  task dmsf_webdav_test_on: :environment do
    prj = Project.new
    prj.identifier = 'dmsf_test_project'
    prj.name = 'DMSF Test Project'
    prj.description = 'A temporary project for Litmus tests'
    prj.enable_module! :dmsf
    Rails.logger.error(prj.errors.full_messages.to_sentence) unless prj.save
    # Settings
    Setting.rest_api_enabled = true
    # Plugin's settings
    plugin_settings = ActiveSupport::HashWithIndifferentAccess.new
    plugin_settings['dmsf_webdav'] = '1'
    plugin_settings['dmsf_webdav_strategy'] = 'WEBDAV_READ_WRITE'
    plugin_settings['dmsf_storage_directory'] = File.join('files', ['dmsf'])
    plugin_settings['dmsf_webdav_authentication'] = 'Basic'
    Setting.plugin_redmine_dmsf = plugin_settings
  end

  task dmsf_webdav_test_off: :environment do
    # Settings
    Setting.rest_api_enabled = false
    # Plugin's settings
    Setting.plugin_redmine_dmsf = nil
    prj = Project.find_by(identifier: 'dmsf_test_project')
    prj&.delete
  end
end
