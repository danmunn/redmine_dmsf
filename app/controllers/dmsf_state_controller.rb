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

class DmsfStateController < ApplicationController
  unloadable
  
  menu_item :dmsf
  
  before_filter :find_project
  before_filter :authorize

  helper :all

  def user_pref_save
    member = @project.members.find(:first, :conditions => {:user_id => User.current.id})
    if member
      member.dmsf_mail_notification = params[:email_notify];
      member.save!
      flash[:notice] = l(:notice_your_preferences_were_saved)  
    else
      flash[:warning] = l(:user_is_not_project_member)
    end
    redirect_to :controller => "projects", :action => 'settings', :tab => 'dmsf', :id => @project
  end
  
  private
  
  def find_project
    @project = Project.find(params[:id])
  end
  
  def check_project(entry)
    if !entry.nil? && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end
  end
  
end
