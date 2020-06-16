# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2019  Jean-Philippe Lang
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

  fixtures :users, :email_addresses

  def setup
    @jsmith = User.find 2
    @item = DmsfFolder.new
  end

  def test_truth
    assert_kind_of User, @jsmith
    assert_kind_of DmsfFolder, @item
  end

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
    assert_equal '1 KB', csv_value(c_size, @item, 1024)
  end

end
