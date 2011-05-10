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
  
  before_filter :find_project
  before_filter :authorize
  before_filter :find_folder, :only => [:folder_notify_activate, :folder_notify_deactivate]
  before_filter :find_file, :only => [:lock_file, :unlock_file, :file_notify_activate, :file_notify_deactivate]

  def lock_file
    if @file.locked?
      flash[:warning] = l(:warning_file_already_locked)
    else
      @file.lock
      flash[:notice] = l(:notice_file_locked)
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @file.folder
  end
  
  def unlock_file
    if !@file.locked?
      flash[:warning] = l(:warning_file_not_locked)
    else
      if @file.locks[0].user == User.current || User.current.allowed_to?(:force_file_unlock, @file.project)
        @file.unlock
        flash[:notice] = l(:notice_file_unlocked)
      else
        flash[:error] = l(:error_only_user_that_locked_file_can_unlock_it)
      end
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @file.folder
  end

  def user_pref
  end

  def user_pref_save
    @user_pref = DmsfUserPref.for(@project, User.current)
    @user_pref.email_notify = params[:email_notify];
    @user_pref.save
    flash[:notice] = l(:notice_your_preferences_were_saved)
    redirect_to :action => "user_pref", :id => @project
  end

  def folder_notify_activate
    if @folder.notification
      flash[:warning] = l(:warning_folder_notifications_already_activated)
    else
      @folder.notify_activate
      flash[:notice] = l(:notice_folder_notifications_activated)
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder.folder
  end
  
  def folder_notify_deactivate
    if !@folder.notification
      flash[:warning] = l(:warning_folder_notifications_already_deactivated)
    else
      @folder.notify_deactivate
      flash[:notice] = l(:notice_folder_notifications_deactivated)
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder.folder
  end
  
  def file_notify_activate
    if @file.notification
      flash[:warning] = l(:warning_file_notifications_already_activated)
    else
      @file.notify_activate
      flash[:notice] = l(:notice_file_notifications_activated)
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @file.folder
  end
  
  def file_notify_deactivate
    if !@file.notification
      flash[:warning] = l(:warning_file_notifications_already_deactivated)
    else
      @file.notify_deactivate
      flash[:notice] = l(:notice_file_notifications_deactivated)
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @file.folder
  end

  private
  
  def find_project
    @project = Project.find(params[:id])
  end
  
  def find_folder
    @folder = DmsfFolder.find(params[:folder_id]) if params.keys.include?("folder_id")
    check_project(@folder)
  rescue DmsfAccessError
    render_403
  end

  def find_file
    check_project(@file = DmsfFile.find(params[:file_id]))
  rescue DmsfAccessError
    render_403
  end

  def check_project(entry)
    if !entry.nil? && entry.project != @project
      raise DmsfAccessError, l(:error_entry_project_does_not_match_current_project) 
    end
  end
  
end