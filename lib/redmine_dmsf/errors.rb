# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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

require 'redmine_dmsf/errors/dmsf_access_error.rb'
require 'redmine_dmsf/errors/dmsf_content_error.rb'
require 'redmine_dmsf/errors/dmsf_email_max_file_error.rb'
require 'redmine_dmsf/errors/dmsf_file_not_found_error.rb'
require 'redmine_dmsf/errors/dmsf_lock_error.rb'
require 'redmine_dmsf/errors/dmsf_zip_max_file_error.rb'