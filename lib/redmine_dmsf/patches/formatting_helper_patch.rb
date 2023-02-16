# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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
  module Patches
    module FormattingHelperPatch

      def heads_for_wiki_formatter
        super
        return if @dmsf_macro_list
        @dmsf_macro_list = []
        Redmine::WikiFormatting::Macros.available_macros.each do |key, value|
          if key.to_s =~ /^dmsf/
            @dmsf_macro_list << key.to_s
          end
        end
        # If localized files for the current language are not available, switch to English
        lang = current_language.to_s.downcase
        path = File.join(File.dirname(__FILE__),
                         '..', '..', '..', 'assets', 'help', lang, 'wiki_syntax.html')
        if File.exist?(path)
          @dmsf_macro_list << "#{lang};#{l(:label_help)}"
        else
          @dmsf_macro_list << "en;#{l(:label_help)}"
        end
        path = File.join(File.dirname(__FILE__),
                         '..', '..', '..', 'assets', 'javascripts', 'lang', "dmsf_button-#{lang}.js")
        unless File.exist?(path)
          lang = 'en'
        end
        content_for :header_tags do
          javascript_include_tag("lang/dmsf_button-#{lang}", plugin: 'redmine_dmsf') +
          javascript_include_tag('dmsf_button', plugin: 'redmine_dmsf') +
            javascript_tag("jsToolBar.prototype.dmsfList = #{@dmsf_macro_list.to_json};")
        end
      end

    end
  end
end

# Apply the patch
Redmine::WikiFormatting::Textile::Helper.prepend RedmineDmsf::Patches::FormattingHelperPatch
Redmine::WikiFormatting::Markdown::Helper.prepend RedmineDmsf::Patches::FormattingHelperPatch
Redmine::WikiFormatting::CommonMark::Helper.prepend RedmineDmsf::Patches::FormattingHelperPatch
