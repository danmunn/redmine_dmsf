# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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
  fixtures :projects, :users, :email_addresses, :dmsf_folders, :roles, 
    :members, :member_roles
         
  def setup    
    @folder6 = DmsfFolder.find_by_id 6
  end
  
  def test_truth
    assert_kind_of DmsfFolder, @folder6
  end
    
  def test_delete        
    assert @folder6.delete(false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted, "Folder #{@folder6} hasn't been deleted"
  end
  
  def test_restore    
    assert @folder6.delete(false), @folder6.errors.full_messages.to_sentence
    assert @folder6.deleted, "Folder #{@folder6} hasn't been deleted"
    assert @folder6.restore, @folder6.errors.full_messages.to_sentence
    assert !@folder6.deleted, "Folder #{@folder6} hasn't been restored"
  end
  
  def test_destroy    
    @folder6.delete true
    assert_nil DmsfFolder.find_by_id(@folder6.id)    
  end
  
end