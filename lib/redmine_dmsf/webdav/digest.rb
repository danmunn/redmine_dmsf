# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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
  module Webdav
    # Replacement for Rack::Auth::Digest
    class Digest
      def initialize(authorization)
        @authorization = authorization
      end

      def params
        params = {}
        parts = @authorization.split(' ', 2)
        split_header_value(parts[1]).each do |param|
          k, v = param.split('=', 2)
          params[k] = dequote(v)
        end
        params
      end

      private

      def dequote(str)
        ret = /\A"(.*)"\Z/ =~ str ? ::Regexp.last_match(1) : str.dup
        ret.gsub(/\\(.)/, '\\1')
      end

      def split_header_value(str)
        str.scan(/(\w+=(?:"[^"]+"|[^,]+))/n).pluck(0)
      end
    end
  end
end
