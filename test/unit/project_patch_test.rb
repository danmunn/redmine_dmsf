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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

# project tests
class ProjectPatchTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_links, :dmsf_workflows, :dmsf_locks, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_project_has_dmsf_files
    assert @project1.respond_to?(:dmsf_files)
  end

  def test_project_has_dmsf_folders
    assert @project1.respond_to?(:dmsf_folders)
  end

  def test_project_has_dmsf_workflows
    assert @project1.respond_to?(:dmsf_workflows)
  end

  def test_project_has_folder_links
    assert @project1.respond_to?(:folder_links)
  end

  def test_project_has_file_links
    assert @project1.respond_to?(:file_links)
  end

  def test_project_has_url_links
    assert @project1.respond_to?(:url_links)
  end

  def test_project_has_dmsf_links
    assert @project1.respond_to?(:dmsf_links)
  end

  def test_project_has_default_dmsf_query
    assert @project1.respond_to?(:default_dmsf_query)
  end

  def test_dmsf_count
    User.current = @jsmith
    hash = @project1.dmsf_count
    assert_equal 9, hash[:files]
    assert_equal 5, hash[:folders]
  end

  def test_copy_approval_workflows
    assert_equal 1, @project1.dmsf_workflows.all.size
    assert_equal 0, @project2.dmsf_workflows.all.size
    @project2.copy_approval_workflows @project1
    assert_equal 1, @project2.dmsf_workflows.all.size
  end

  def test_copy_dmsf
    User.current = @jsmith

    assert_equal 5, @project1.dmsf_files.visible.all.size
    assert_equal 3, @project1.dmsf_folders.visible.all.size
    assert_equal 2, @project1.file_links.visible.all.size
    assert_equal 1, @project1.folder_links.visible.all.size
    assert_equal 0, @project1.url_links.visible.all.size

    assert_equal 1, @project5.dmsf_files.visible.all.size
    assert_equal 1, @project5.dmsf_folders.visible.all.size
    assert_equal 0, @project5.file_links.visible.all.size
    assert_equal 0, @project5.folder_links.visible.all.size
    assert_equal 0, @project5.url_links.visible.all.size

    @project5.copy_dmsf @project1

    assert_equal 6, @project5.dmsf_files.visible.all.size
    assert_equal 4, @project5.dmsf_folders.visible.all.size
    assert_equal 2, @project5.file_links.visible.all.size
    assert_equal 1, @project5.folder_links.visible.all.size
    assert_equal 0, @project5.url_links.visible.all.size
  end

  def test_dmsf_avaliable
    # @project1 (:dmsf, manager)
    #   L @project3 (:dmsf), @project4, @project5
    User.current = @jsmith
    assert @project1.dmsf_available?
    assert_not @project3.dmsf_available?
  end

  def test_watchable
    @project1.add_watcher @jsmith
    assert @project1.watched_by?(@jsmith)
  end
end
