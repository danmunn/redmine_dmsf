# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

DMSF_MAX_NOTIFICATION_RECEIVERS_INFO = 10

# DMSF libraries

# Plugin's patches
require 'redmine_dmsf/patches/custom_fields_helper_patch'
require 'redmine_dmsf/patches/acts_as_customizable'
require 'redmine_dmsf/patches/project_patch'
require 'redmine_dmsf/patches/project_tabs_extended'
require 'redmine_dmsf/patches/user_preference_patch'
require 'redmine_dmsf/patches/user_patch'
require 'redmine_dmsf/patches/issue_patch'
require 'redmine_dmsf/patches/application_helper_patch'

# Load up classes that make up our WebDAV solution ontop of DAV4Rack
require 'redmine_dmsf/webdav/base_resource'
require 'redmine_dmsf/webdav/controller'
require 'redmine_dmsf/webdav/cache'
require 'redmine_dmsf/webdav/dmsf_resource'
require 'redmine_dmsf/webdav/download'
require 'redmine_dmsf/webdav/index_resource'
require 'redmine_dmsf/webdav/project_resource'
require 'redmine_dmsf/webdav/resource_proxy'

# Exceptions
require 'redmine_dmsf/errors/dmsf_access_error.rb'
require 'redmine_dmsf/errors/dmsf_content_error.rb'
require 'redmine_dmsf/errors/dmsf_email_max_file_error.rb'
require 'redmine_dmsf/errors/dmsf_file_not_found_error.rb'
require 'redmine_dmsf/errors/dmsf_lock_error.rb'
require 'redmine_dmsf/errors/dmsf_zip_max_file_error.rb'

# Hooks
require 'redmine_dmsf/hooks/controllers/search_controller_hooks'
require 'redmine_dmsf/hooks/controllers/issues_controller_hooks'
require 'redmine_dmsf/hooks/views/view_projects_form_hook'
require 'redmine_dmsf/hooks/views/base_view_hooks'
require 'redmine_dmsf/hooks/views/my_account_view_hooks'
require 'redmine_dmsf/hooks/views/issue_view_hooks'
require 'redmine_dmsf/hooks/views/custom_field_view_hooks'
require 'redmine_dmsf/hooks/helpers/issues_helper_hooks'

# Macros
require 'redmine_dmsf/macros'
