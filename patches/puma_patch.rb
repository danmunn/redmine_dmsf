# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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
#
# Redmine's PDF export patch to view DMS images

module RedmineDmsf
  module Patches
    # Puma
    module PumaPatch
      ##################################################################################################################
      # Overridden methods
      def self.included(base)
        base.class_eval do
          # WebDAV methods
          methods = Puma::Const::SUPPORTED_HTTP_METHODS |
                    %w[OPTIONS HEAD GET PUT POST DELETE PROPFIND PROPPATCH MKCOL COPY MOVE LOCK UNLOCK]
          remove_const :SUPPORTED_HTTP_METHODS
          const_set :SUPPORTED_HTTP_METHODS, methods.freeze
        end
      end
    end
  end
end

# Apply the patch
if !defined?(EasyPatchManager) && RedmineDmsf::Plugin.lib_available?('puma/const')
  Puma::Const.include RedmineDmsf::Patches::PumaPatch
end
