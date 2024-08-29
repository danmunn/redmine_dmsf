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

module RedmineDmsf
  module Hooks
    module Controllers
      # Account controller hooks
      class AccountControllerHooks < Redmine::Hook::Listener
        def controller_account_success_authentication_after(context = {})
          return unless context.is_a?(Hash)

          controller = context[:controller]
          return unless controller

          user = context[:user]
          return unless user

          return unless Setting.plugin_redmine_dmsf['dmsf_webdav_authentication'] == 'Digest'

          # Updates user's DMSF WebDAV digest
          if controller.params[:password].present?
            token = Token.find_by(user_id: user.id, action: 'dmsf_webdav_digest')
            token ||= Token.create!(user_id: user.id, action: 'dmsf_webdav_digest')
            token.value = ActiveSupport::Digest.hexdigest(
              "#{user.login}:#{RedmineDmsf::Webdav::AUTHENTICATION_REALM}:#{controller.params[:password]}"
            )
            token.save
          end
        rescue StandardError => e
          Rails.logger.error e.message
        end
      end
    end
  end
end
