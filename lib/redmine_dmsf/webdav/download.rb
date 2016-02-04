# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

require 'time'
require 'rack/utils'
require 'rack/mime'

module RedmineDmsf
  module Webdav
    class Download < Rack::File
      def initialize(root, cache_control = nil)
        @path = root
        @cache_control = cache_control
      end

      def _call(env)
        unless ALLOWED_VERBS.include? env['REQUEST_METHOD']
          return fail(405, 'Method Not Allowed')
        end

        available = begin
          F.file?(@path) && F.readable?(@path)
        rescue SystemCallError
          false
        end

        if available
          serving(env)
        else
          raise NotFound
        end
      end
    end
  end
end