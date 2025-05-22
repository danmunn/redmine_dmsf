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
    module Helpers
      # Issue helper hooks
      class IssuesHelperHooks < Redmine::Hook::Listener
        def helper_issues_show_detail_after_setting(context)
          return unless context.is_a?(Hash)

          detail = context[:detail]
          case detail.property
          when 'dmsf_file'
            detail.prop_key = l(:label_document)
            detail.property = 'attachment'
          end
        end
      end
    end
  end
end
