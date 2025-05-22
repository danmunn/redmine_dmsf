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
      # Search helper hooks
      class SearchHelperHooks < Redmine::Hook::Listener
        def helper_easy_extensions_search_helper_patch(context = {})
          case context[:entity].event_type
          when 'dmsf-file', 'dmsf-folder'
            str = context[:controller].send(:render_to_string,
                                            partial: 'search/container',
                                            locals: { object: context[:entity] })
            if str
              html = +'<p class=\"file-detail-container\"><span><strong>'
              html << if context[:entity].dmsf_folder_id
                        context[:entity].class.human_attribute_name(:folder)
                      else
                        context[:entity].class.human_attribute_name(:project)
                      end
              html << ':</strong>'
              html << str
              html << '</span></p>'
              context[:additional_result] << html
            end
          end
        end
      end
    end
  end
end
