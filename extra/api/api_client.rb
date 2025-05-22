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

require 'rubygems'
require 'active_resource'

# Simple REST API client in Ruby
# usage: ruby api_client.rb [login] [password]

# Dmsf file
class DmsfFile < ActiveResource::Base
  self.site = 'https://localhost:3000/'
  self.user = ARGV[0]
  self.password = ARGV[1]
end

# 2. Get a document
FILE_ID = 41_532
file = DmsfFile.find FILE_ID
if file
  puts file.id
  puts file.title
  puts file.name
  puts file.version
  puts file.project_id
  puts file.content_url
else
  puts "No file with id = #{FILE_ID} found"
end
