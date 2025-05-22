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
      # Custom field view hooks
      class CustomFieldViewHooks < Redmine::Hook::ViewListener
        def view_custom_fields_form_dmsf_file_revision_custom_field(context = {})
          html = +''
          if context.is_a?(Hash) && context[:form]
            # Add the inheritable option
            f = context[:form]
            html = content_tag(:p, f.check_box(:dmsf_not_inheritable))
            # Add is filter option
            if context[:custom_field]
              custom_field = context[:custom_field]
              html << content_tag(:p, f.check_box(:is_filter)) if custom_field.format.is_filter_supported
            end
          end
          html
        end
      end
    end
  end
end
