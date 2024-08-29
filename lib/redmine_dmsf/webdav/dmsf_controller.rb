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
    # DMSF controller
    class DmsfController < Dav4rack::Controller
      include Redmine::I18n
      include AbstractController::Callbacks

      around_action :switch_locale

      def switch_locale(&action)
        # Switch the locale to English for WebDAV requests in order to have log messages in English
        I18n.with_locale(:en, &action)
      end

      def process
        return super unless Setting.plugin_redmine_dmsf['dmsf_webdav_authentication'] == 'Digest'

        status = skip_authorization? || authenticate ? process_action || OK : Dav4rack::HttpStatus::Unauthorized
      rescue Dav4rack::HttpStatus::Status => e
        status = e
      ensure
        if status
          response.status = status.code
          if status.code == 401
            time_stamp = Time.now.to_i
            h_once = ActiveSupport::Digest.hexdigest("#{time_stamp}:#{SecureRandom.hex(32)}")
            nonce = Base64.strict_encode64("#{time_stamp}#{h_once}")
            response['WWW-Authenticate'] =
              %(Digest realm="#{authentication_realm}", nonce="#{nonce}", algorithm="MD5", qop="auth")
          end
        end
      end

      def authenticate
        return super unless Setting.plugin_redmine_dmsf['dmsf_webdav_authentication'] == 'Digest'

        auth_header = request.authorization.to_s
        scheme = auth_header.split(' ', 2).first&.downcase
        if scheme == 'digest'
          Rails.logger.info 'Authentication: digest'
          auth = Rack::Auth::Digest::Request.new(request.env)
          params = auth.params
          username = params['username']
          response = params['response']
          cnonce = params['cnonce']
          nonce = params['nonce']
          uri = params['uri']
          qop = params['qop']
          nc = params['nc']
          user = User.find_by(login: username)
          unless user
            Rails.logger.error "Digest authentication: #{username} not found"
            raise Unauthorized
          end
          unless user.active?
            Rails.logger.error l(:notice_account_locked)
            raise Unauthorized
          end
          token = Token.find_by(user_id: user.id, action: 'dmsf_webdav_digest')
          if token.nil? && defined?(EasyExtensions)
            if user.easy_digest_token_expired?
              Rails.logger.error "Digest authentication: #{user} is locked"
              raise Unauthorized
            end
            ha1 = user.easy_digest_token
          else
            unless token
              Rails.logger.error "Digest authentication: no digest found for #{username}"
              raise Unauthorized
            end
            ha1 = token.value
          end
          ha2 = ActiveSupport::Digest.hexdigest("#{request.env['REQUEST_METHOD']}:#{uri}")
          required_response = if qop
                                ActiveSupport::Digest.hexdigest("#{ha1}:#{nonce}:#{nc}:#{cnonce}:#{qop}:#{ha2}")
                              else
                                ActiveSupport::Digest.hexdigest("#{ha1}:#{nonce}:#{ha2}")
                              end
          if required_response == response
            User.current = user
          else
            Rails.logger.error 'Digest authentication: digest response is incorrect'
          end
        else
          Rails.logger.warn "Digest authentication method expected got '#{scheme}'"
        end
        raise Unauthorized if User.current.anonymous?

        Rails.logger.info "Current user: #{User.current}, User-Agent: #{request.user_agent}"
        User.current
      end
    end
  end
end
