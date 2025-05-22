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

module RedmineDmsf
  module Hooks
    module Views
      # Search view hooks
      class SearchViewHooks < Redmine::Hook::ViewListener
        def view_search_index_container(context = {})
          return unless context[:object].is_a?(DmsfFile) || context[:object].is_a?(DmsfFolder)

          str = context[:controller].send(:render_to_string,
                                          partial: 'search/container',
                                          locals: { object: context[:object] })
          " #{str} /" if str
        end
      end
    end
  end
end
