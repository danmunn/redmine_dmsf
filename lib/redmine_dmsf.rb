# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Pičman <karel.picman@kontron.com>
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
require 'redmine_dmsf/patches' #plugin patches
require 'redmine_dmsf/webdav' #DAV4Rack implementation


# Hooks
require 'redmine_dmsf/hooks/view_projects_form_hook'
require 'redmine_dmsf/hooks/base_view_hooks'

module RedmineDmsf
end

# Add the plugin view folder into ActionMailer's paths to search
ActionMailer::Base.append_view_path(File.expand_path(File.dirname(__FILE__) + '/../app/views'))