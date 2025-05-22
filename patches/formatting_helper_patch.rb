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
  module Patches
    # Formatting helper
    module FormattingHelperPatch
      def heads_for_wiki_formatter
        super
        return if @dmsf_macro_list

        @dmsf_macro_list = []
        Redmine::WikiFormatting::Macros.available_macros.each_key do |key|
          @dmsf_macro_list << key.to_s if key.to_s.match?(/^dmsf/)
        end
        # If localized files for the current language are not available, switch to English
        lang = current_language.to_s.downcase
        path = File.join(File.dirname(__FILE__),
                         '..', '..', '..', 'assets', 'help', lang, 'wiki_syntax.html')
        @dmsf_macro_list << (File.exist?(path) ? "#{lang};#{l(:label_help)}" : "en;#{l(:label_help)}")
        path = File.join(File.dirname(__FILE__),
                         '..', '..', '..', 'assets', 'javascripts', 'lang', "dmsf_button-#{lang}.js")
        lang = 'en' unless File.exist?(path)
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
Redmine::WikiFormatting::CommonMark::Helper.prepend RedmineDmsf::Patches::FormattingHelperPatch
