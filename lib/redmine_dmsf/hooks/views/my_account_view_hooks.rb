# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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
    include Redmine::Hook

    class MyAccountViewHook < Redmine::Hook::ViewListener

      render_on :view_users_bulk_edit, :partial => 'hooks/redmine_dmsf/view_users_bulk_edit'

      def view_my_account_preferences(context={})
        if context.is_a?(Hash) && context[:user]
          context[:controller].send(
            :render_to_string, {
              :partial => 'hooks/redmine_dmsf/view_my_account',
              :locals => context
          }).html_safe
        end
      end

    end
  end
end