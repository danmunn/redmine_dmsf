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

require File.expand_path('../../test_helper', __FILE__)

# Queries helper
class DmsfQueriesHelperTest < RedmineDmsf::Test::HelperTest
  include DmsfQueriesHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper

  fixtures :dmsf_folders

  def setup
    @folder1 = DmsfFolder.find 1
    super
  end

  def test_csv_value
    # Size
    column = QueryColumn.new(:size)
    assert_equal '1 KB', csv_value(column, nil, 1024)
    # Author
    column = QueryColumn.new(:author)
    assert_equal 'John Smith', csv_value(column, @jsmith, @jsmith.id)
  end

  def test_column_value
    # Size
    column = QueryColumn.new(:size)
    assert_equal '1 KB', column_value(column, @folder1, 1024)
    # Comment
    column = QueryColumn.new(:comment)
    assert column_value(column, @folder1, '*Comment*').include?('wiki')
  end

  def test_previewable
    assert previewable?('file.txt', 'text/plain')
    assert previewable?('main.c', 'text/x-csrc')
    assert_not previewable?('document.odt', 'application/vnd.oasis.opendocument.text')
  end
end
