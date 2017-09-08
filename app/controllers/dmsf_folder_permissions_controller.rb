# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@konton.com>
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

class DmsfFolderPermissionsController < ApplicationController
  unloadable

  before_action :find_folder, :only => [:destroy]
  before_action :find_project
  before_action :authorize
  before_action :permissions

  def permissions
    render_403 unless DmsfFolder.permissions?(@dmsf_folder)
    true
  end

  def new
    @principals = users_for_new_users
  end

  def append
    @principals = Principal.where(:id => params[:user_ids]).to_a
    head 200 if @principals.blank?
  end

  def autocomplete_for_user
    @principals = users_for_new_users
    respond_to do |format|
      format.js
    end
  end

  private

  def users_for_new_users
    Principal.active.visible.member_of(@project).like(params[:q]).order(:type, :lastname).to_a
  end

  def find_project
    if params[:project_id]
      @project = Project.visible.find_by_param(params[:project_id])
    end
  end

  def find_folder
    if params[:dmsf_folder_id]
      @dmsf_folder = DmsfFolder.visible.find_by_id(params[:dmsf_folder_id])
    end
  end

end
