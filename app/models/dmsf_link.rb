# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-14 Karel Pičman <karel.picman@lbcfree.net>
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

class DmsfLink < ActiveRecord::Base
  unloadable
    
  belongs_to :project
  belongs_to :dmsf_folder
  validates :name, :presence => true
  validates :target_id, :presence => true
  validates_length_of :name, :maximum => 255    
  scope :visible, :conditions => 'deleted = 0'      
  
  def target_folder_id
    if self.target_type == DmsfFolder.model_name
      self.target_id
    else
      f = DmsfFile.find_by_id self.target_id
      f.dmsf_folder_id if f
    end
  end
  
  def target_folder
    DmsfFolder.find_by_id self.target_folder_id if self.target_folder_id
  end
  
  def target_file_id
    self.target_id if self.target_type == DmsfFile.model_name
  end
  
  def target_file
    DmsfFile.find_by_id self.target_file_id if self.target_file_id
  end
  
  def target_project
    Project.find_by_id self.target_project_id  
  end
  
  def folder
    DmsfFolder.find_by_id self.dmsf_folder_id
  end
  
  def title
    self.name
  end
   
end
