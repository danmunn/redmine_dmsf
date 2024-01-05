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

require 'time'
require 'uri'
require 'nokogiri'
require 'ox'
require 'digest'
require 'rack'

require "#{File.dirname(__FILE__)}/dav4rack/utils"
require "#{File.dirname(__FILE__)}/dav4rack/http_status"
require "#{File.dirname(__FILE__)}/dav4rack/resource"
require "#{File.dirname(__FILE__)}/dav4rack/handler"
require "#{File.dirname(__FILE__)}/dav4rack/controller"

module Dav4rack
  IS_18 = RUBY_VERSION[0, 3] == '1.8'
end
