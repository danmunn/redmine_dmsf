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

# Files helper
module DmsfFilesHelper
  def clean_wiki_text(text)
    # If there is <p> tag, the text is moved one column to the right by Redmin's CSS. A new line causes double new line.
    text.gsub('<p>', '')
        .gsub('</p>', '')
        .gsub("\n\n", '<br>')
        .gsub("\n\t", '<br>')
  end

  def render_document_content(dmsf_file, content)
    if dmsf_file.markdown?
      render partial: 'common/markup', locals: { markup_text_formatting: markdown_formatter, markup_text: content }
    elsif dmsf_file.textile?
      render partial: 'common/markup', locals: { markup_text_formatting: 'textile', markup_text: content }
    else
      render partial: 'common/file', locals: { content: content, filename: dmsf_file.name }
    end
  end
end
