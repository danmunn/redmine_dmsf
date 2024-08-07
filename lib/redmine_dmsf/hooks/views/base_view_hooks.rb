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
    module Views
      # Base view hooks
      class BaseViewHooks < Redmine::Hook::ViewListener
        def view_layouts_base_html_head(context = {})
          unless /^(Dmsf|Projects|Issues|Queries|EasyCrmCases|MyController|SettingsController|WikiController)/.match?(
            context[:controller].class.name
          )
            return
          end

          "\n".html_safe + stylesheet_link_tag('redmine_dmsf.css', plugin: :redmine_dmsf) +
            "\n".html_safe + stylesheet_link_tag('select2.min.css', plugin: :redmine_dmsf) +
            "\n".html_safe + javascript_include_tag('select2.min.js', plugin: :redmine_dmsf, defer: true) +
            "\n".html_safe + javascript_include_tag('redmine_dmsf.js', plugin: :redmine_dmsf, defer: true) +
            "\n".html_safe + javascript_include_tag('attachments_dmsf.js', plugin: :redmine_dmsf, defer: true)
        end
      end
    end
  end
end
