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

    class DmsfViewListener < Redmine::Hook::ViewListener

      def view_issues_form_details_bottom(context={})
        if context.is_a?(Hash) && context[:issue]
          # Add Dmsf upload form
          html = "<div class=\"dmsf_uploader\">"
          html << '<p>'
          html << "<label>#{l(:label_document_plural)}</label>"
          html << context[:controller].send(:render_to_string,
            {:partial => 'dmsf_upload/form', :locals => { :multiple => true }})
          html << '</p>'
          html << '</div>'
          html.html_safe
        end
      end

      def view_issues_show_description_bottom(context={})
        if context.is_a?(Hash) && context[:issue]
          issue = context[:issue]
          context[:controller].send(:render_to_string, {:partial => 'dmsf_files/links',
            :locals => { :dmsf_files => issue.dmsf_files.to_a, :thumbnails => Setting.thumbnails_enabled? }})
        end
      end

    end
  end
end
