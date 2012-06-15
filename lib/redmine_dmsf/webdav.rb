# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

# Load up classes that make up our webdav solution ontop
# of DAV4Rack
require 'redmine_dmsf/webdav/no_parse'
require 'redmine_dmsf/webdav/base_resource'
require 'redmine_dmsf/webdav/controller'
require 'redmine_dmsf/webdav/dmsf_resource'
require 'redmine_dmsf/webdav/download'
require 'redmine_dmsf/webdav/index_resource'
require 'redmine_dmsf/webdav/project_resource'
require 'redmine_dmsf/webdav/resource_proxy'
