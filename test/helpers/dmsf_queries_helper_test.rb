# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
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

require File.expand_path('../../test_helper', __FILE__)

class DmsfQueriesHelperTest < RedmineDmsf::Test::HelperTest
  include DmsfQueriesHelper
  fixtures :dmsf_folders


  def test_csv_value
    c_size = QueryColumn.new(:size)
    c_author = QueryColumn.new(:author)
    c_workflow = QueryColumn.new(:workflow)
    assert_equal '1 KB', csv_value(c_size, nil, 1024)
    assert_equal 'John Smith', csv_value(c_author, @jsmith, @jsmith.id)
    assert_equal 'Approved', csv_value(c_workflow, nil, DmsfWorkflow::STATE_APPROVED)
  end

  def test_column_value
    c_size = QueryColumn.new(:size)
    assert_equal '1 KB', csv_value(c_size, @folder1, 1024)
  end

end
