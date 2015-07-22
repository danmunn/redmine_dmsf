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

module RedmineDmsf
  class NoParse
    def initialize(app, options={})
      @app = app
      @urls = options[:urls]
    end

    def call(env)
      if env['REQUEST_METHOD'] == "PUT" && env.has_key?('CONTENT_TYPE') then
        if (@urls.dup.delete_if {|x| !env['PATH_INFO'].starts_with? x}.length > 0) then
          logger "RedmineDmsf::NoParse prevented mime parsing for PUT #{env['PATH_INFO']}"
          env['CONTENT_TYPE'] = 'text/plain'
        end
      end
      @app.call(env)
    end

    private

      def logger(env)
        env['action_dispatch.logger'] || Logger.new($stdout)
      end

  end
end

# Todo:
#   This should probably be configurable somehow or better have the module hunt for the correct pathing
#   automatically without the need to add a "/dmsf/webdav" configuration to it, as if the route is changed
#   the functonality of this patch will effectively break.
Rails.configuration.middleware.insert_before(
  ActionDispatch::ParamsParser,
  RedmineDmsf::NoParse, :urls => ["#{Redmine::Utils::relative_url_root}/dmsf/webdav"])