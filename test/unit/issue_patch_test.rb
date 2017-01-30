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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class IssuePatchTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :dmsf_files, :dmsf_file_revisions, :issues
  def setup
    @issue1 = Issue.find_by_id 1
  end

  def test_truth
    assert_kind_of Issue, @issue1
  end

  def test_issue_has_dmsf_files
    assert @issue1.respond_to?(:dmsf_files)
  end

end