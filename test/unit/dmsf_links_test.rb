# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2014 Karel Pičman <karel.picman@lbcfree.net>
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

class DmsfLinksTest < RedmineDmsf::Test::UnitTest
  
  fixtures :projects, :members, :dmsf_files, :dmsf_file_revisions, 
    :dmsf_folders, :dmsf_links

  def setup
    @project1 = Project.find_by_id 1
    @folder1 = DmsfFolder.find_by_id 1
    @folder2 = DmsfFolder.find_by_id 2
    @file1 = DmsfFile.find_by_id 1
    @file4 = DmsfFile.find_by_id 4
    @folder_link = DmsfLink.find_by_id 1
    @file_link = DmsfLink.find_by_id 2
  end
  
  def test_truth
    assert_kind_of Project, @project1
    assert_kind_of DmsfFolder, @folder1
    assert_kind_of DmsfFolder, @folder2
    assert_kind_of DmsfFile, @file1
    assert_kind_of DmsfFile, @file4
    assert_kind_of DmsfLink, @folder_link
    assert_kind_of DmsfLink, @file_link    
  end
  
  def test_create
    # Folder link
    folder_link = DmsfLink.new(
      :target_project_id => @project1.id,
      :target_id => @folder1.id,
      :target_type => DmsfFolder.model_name,
      :name => 'folder1_link2',
      :project_id => @project1.id,
      :created_at => DateTime.now(),
      :updated_at => DateTime.now())
    assert folder_link.save
    
    # File link
    file_link = DmsfLink.new(
      :target_project_id => @project1.id,
      :target_id => @file1.id,
      :target_type => DmsfFile.model_name,
      :name => 'file1_link2',
      :project_id => @project1.id,
      :created_at => DateTime.now(),
      :updated_at => DateTime.now())
    assert file_link.save
  end
  
  def test_validate_name_length
    @folder_link.name = 'a' * 256
    assert !@folder_link.save
    assert_equal 1, @folder_link.errors.count        
  end
  
  def test_validate_name_presence
    @folder_link.name = ''
    assert !@folder_link.save
    assert_equal 1, @folder_link.errors.count        
  end
  
  def test_validate_target_id_presence
    @folder_link.target_id = nil
    assert !@folder_link.save
    assert_equal 1, @folder_link.errors.count        
  end
  
  def test_belongs_to_project
    @project1.destroy
    assert_nil DmsfLink.find_by_id 1
    assert_nil DmsfLink.find_by_id 2
  end
  
  def test_belongs_to_dmsf_folder
    @folder1.destroy
    assert_nil DmsfLink.find_by_id 1
    assert_nil DmsfLink.find_by_id 2
  end
  
  def test_target_folder_id
    assert_equal 2, @file_link.target_folder_id
    assert_equal 1, @folder_link.target_folder_id    
  end
  
  def test_target_folder
    assert_equal @folder2, @file_link.target_folder
    assert_equal @folder1, @folder_link.target_folder
  end
  
  def test_target_file_id
    assert_equal 4, @file_link.target_file_id
    assert_nil @folder_link.target_file
  end
  
  def test_target_file
    assert_equal @file4, @file_link.target_file
    assert_nil @folder_link.target_file
  end
  
  def test_target_project
    assert_equal @project1, @file_link.target_project
    assert_equal @project1, @folder_link.target_project
  end
  
  def test_folder
    assert_equal @folder1, @file_link.folder
    assert_nil @folder_link.folder
  end
  
  def test_title
    assert_equal @file_link.name, @file_link.title
    assert_equal @folder_link.name, @folder_link.title
  end
  
  def test_find_link_by_file_name
    assert_equal @file_link, 
      DmsfLink.find_link_by_file_name(@file_link.project, @file_link.folder, @file_link.target_file.name)
  end
  
  def test_path
    assert_equal @file_link.path,
      @file_link.target_file.dmsf_path_str
    assert_equal @folder_link.path,
      @folder_link.target_folder.dmsf_path_str
  end
  
  def test_copy_to
    # File link
    file_link_copy = @file_link.copy_to @folder2.project, @folder2
    assert_not_nil file_link_copy
    assert_equal file_link_copy.target_project_id, @file_link.target_project_id
    assert_equal file_link_copy.target_id, @file_link.target_id
    assert_equal file_link_copy.target_type, @file_link.target_type
    assert_equal file_link_copy.name, @file_link.name
    assert_equal file_link_copy.project_id, @folder2.project.id
    assert_equal file_link_copy.dmsf_folder_id, @folder2.id    
    
    # Folder link
    folder_link_copy = @folder_link.copy_to @folder2.project, @folder2
    assert_not_nil folder_link_copy
    assert_equal folder_link_copy.target_project_id, @folder_link.target_project_id
    assert_equal folder_link_copy.target_id, @folder_link.target_id
    assert_equal folder_link_copy.target_type, @folder_link.target_type
    assert_equal folder_link_copy.name, @folder_link.name
    assert_equal folder_link_copy.project_id, @folder2.project.id
    assert_equal folder_link_copy.dmsf_folder_id, @folder2.id    
  end
  
  def test_destroy      
    @folder_link.destroy
    assert_nil DmsfLink.find_by_id 1
  end
   
end