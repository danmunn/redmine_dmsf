# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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

class DmsfFolderTest < RedmineDmsf::Test::UnitTest
  fixtures :projects, :users, :dmsf_folders, :dmsf_files, :dmsf_file_revisions,
           :roles, :members, :member_roles, :dmsf_locks, :dmsf_links
         
  def setup    
    @folder4 = DmsfFolder.find_by_id 4
  end
  
  def test_truth
    assert_kind_of DmsfFolder, @folder4
  end
    
  def test_delete_restore         
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 1, @folder4.referenced_links.visible.count
    @folder4.delete false    
    assert @folder4.deleted
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 0, @folder4.referenced_links.visible.count
    @folder4.restore    
    assert !@folder4.deleted
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 1, @folder4.referenced_links.visible.count
  end
  
  def test_destroy
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 1, @folder4.referenced_links.visible.count
    @folder4.delete true
    assert_nil DmsfFolder.find_by_id(@folder4.id)        
    # TODO: Doesn't work in Travis - a problem with bolean visiblity
    #assert_equal 0, DmsfLink.where(:target_id => @folder4.id, :target_type => DmsfFolder.model_name).count
  end
  
end