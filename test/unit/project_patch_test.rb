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

class ProjectPatchTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :dmsf_files, :dmsf_file_revisions, :dmsf_links, :dmsf_folders, :dmsf_workflows, :users

  def setup
    @project1 = Project.find_by_id 1
    @project2 = Project.find_by_id 2
    @project3 = Project.find_by_id 3
    admin = User.find 1
    User.current = admin
  end

  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of Project, @project2
    assert_kind_of Project, @project3
  end

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

  def test_dmsf_count
    hash = @project1.dmsf_count
    assert_equal 9, hash[:files]
    assert_equal 7, hash[:folders]
  end

  def test_copy_approval_workflows
    assert_equal 1, @project1.dmsf_workflows.count
    assert_equal 0, @project2.dmsf_workflows.count
    @project2.copy_approval_workflows(@project1)
    assert_equal 1, @project2.dmsf_workflows.count
  end

  def test_copy_dmsf
    assert_equal 4, @project1.dmsf_files.visible.count
    assert_equal 4, @project1.dmsf_folders.visible.count
    assert_equal 1, @project1.file_links.visible.count
    assert_equal 1, @project1.folder_links.visible.count
    assert_equal 1, @project1.url_links.visible.count
    assert_equal 0, @project3.dmsf_files.visible.count
    assert_equal 0, @project3.dmsf_folders.count
    assert_equal 0, @project3.file_links.visible.count
    assert_equal 0, @project3.folder_links.visible.count
    assert_equal 0, @project3.url_links.visible.count
    @project3.copy_dmsf(@project1)
    assert_equal 4, @project3.dmsf_files.visible.count
    assert_equal 4, @project3.dmsf_folders.count
    assert_equal 1, @project3.file_links.visible.count
    assert_equal 1, @project3.folder_links.visible.count
    assert_equal 1, @project3.url_links.visible.count
  end

end