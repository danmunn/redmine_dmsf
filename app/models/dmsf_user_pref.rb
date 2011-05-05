# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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

class DmsfUserPref < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :user
  
  validates_presence_of :project, :user
  validates_uniqueness_of :user_id, :scope => [:project_id]  
  
  def self.for(project, user)
    user_pref = find(:first, :conditions => 
      ["project_id = :project_id and user_id = :user_id", 
        {:project_id => project.id, :user_id => user.id}])
    user_pref = DmsfUserPref.new({:project_id => project.id, :user_id => user.id,
      :email_notify => nil}) if user_pref.nil?
    return user_pref
  end
  
end

