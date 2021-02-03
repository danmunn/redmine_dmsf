# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFoldersCopyController < ApplicationController

  menu_item :dmsf

  before_action :find_folder
  before_action :authorize
  before_action :find_target_folder
  before_action :check_target_folder, only: [:copy, :move]

  def new
    @projects = DmsfFolder.allowed_target_projects_on_copy
    @folders = DmsfFolder.directory_tree(@target_project, @folder)
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    render layout: !request.xhr?
  end

  def copy
    new_folder = @folder.copy_to(@target_project, @target_folder)
    if new_folder.errors.empty?
      flash[:notice] = l(:notice_successful_update)
      redirect_to dmsf_folder_path(id: @target_project, folder_id: new_folder)
    else
      flash[:error] = new_folder.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  def move
    if @folder.move_to(@target_project, @target_folder)
      flash[:notice] = l(:notice_successful_update)
      redirect_to dmsf_folder_path(id: @target_project, folder_id: @folder)
    else
      flash[:error] = @folder.errors.full_messages.to_sentence
      redirect_to :back
    end
  end

  private

  def find_folder
    raise ActiveRecord::RecordNotFound unless DmsfFolder.where(id: params[:id]).exists?
    @folder = DmsfFolder.visible.find params[:id]
    raise DmsfAccessError if @folder.locked_for_user?
    @project = @folder.project
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue DmsfAccessError
    render_403
  end

  def find_target_folder
    if params[:target_project_id].present?
      @target_project = Project.find params[:target_project_id]
    else
      @target_project = @project
    end
    if params[:target_folder_id].present?
      @target_folder = DmsfFolder.find(params[:target_folder_id])
      raise ActiveRecord::RecordNotFound unless DmsfFolder.visible.where(id: params[:target_folder_id]).exists?
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_target_folder
    if (@target_folder && @target_folder == @folder.dmsf_folder) ||
      (@target_folder.nil? && @folder.dmsf_folder.nil? && @target_project == @folder.project)
      flash[:error] = l(:error_target_folder_same)
      redirect_to action: :new, id: @folder, target_project_id: @target_project.id, target_folder_id: @target_folder
      return
    end
    if (@target_folder && (@target_folder.locked_for_user? || !DmsfFolder.permissions?(@target_folder, false))) ||
      !@target_project.allows_to?(:folder_manipulation)
      raise DmsfAccessError
    end
  rescue DmsfAccessError
    render_403
  end

end
