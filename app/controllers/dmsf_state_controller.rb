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
    @user_pref = DmsfUserPref.for(@project, User.current)
    @user_pref.email_notify = params[:email_notify];
    @user_pref.save
    flash[:notice] = "Your preferences was saved"
    redirect_to URI.unescape(params[:current])
  end

  def folder_notify_activate
    if @folder.notification
      flash[:warning] = "Folder notifications already activated"
    else
      @folder.notify_activate
      flash[:notice] = "Folder notifications activated"
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder.folder
  end
  
  def folder_notify_deactivate
    if !@folder.notification
      flash[:warning] = "Folder notifications already deactivated"
    else
      @folder.notify_deactivate
      flash[:notice] = "Folder notifications deactivated"
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @folder.folder
  end
  
  def file_notify_activate
    if @file.notification
      flash[:warning] = "File notifications already activated"
    else
      @file.notify_activate
      flash[:notice] = "File notifications activated"
    end
    redirect_to :controller => "dmsf", :action => "index", :id => @project, :folder_id => @file.folder
  end
  
  def file_notify_deactivate
    if !@file.notification
      flash[:warning] = "File notifications already deactivated"
    else
      @file.notify_deactivate
      flash[:notice] = "File notifications deactivated"
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
      raise DmsfAccessError, "Entry project doesn't match current project" 
    end
  end
  
end