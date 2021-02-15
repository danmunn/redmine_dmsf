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

class DmsfFilesCopyController < ApplicationController

  menu_item :dmsf

  before_action :find_file
  before_action :authorize
  before_action :find_target_folder
  before_action :check_target_folder, only: [:copy, :move]

  def new
    @projects = DmsfFile.allowed_target_projects_on_copy
    @folders = DmsfFolder.directory_tree(@target_project, @folder)
    @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    render layout: !request.xhr?
  end

  def copy
    new_file = @file.copy_to(@target_project, @target_folder)
    if new_file.nil? || new_file.errors.present?
      flash[:error] = new_file ? new_file.errors.full_messages.to_sentence : @file.errors.full_messages.to_sentence
      redirect_to action: 'new', id: @file, target_project_id: @target_project, target_folder_id: @target_folder
      return
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to dmsf_file_path(new_file)
  end

  def move
    unless @file.move_to(@target_project, @target_folder)
      flash[:error] = @file.errors.full_messages.to_sentence
      redirect_to action: 'new', id: @file, target_project_id: @target_project, target_folder_id: @target_folder
      return
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to dmsf_file_path(@file)
  end

private

  def find_file
    raise ActiveRecord::RecordNotFound unless DmsfFile.where(id: params[:id]).exists?
    @file = DmsfFile.visible.find params[:id]
    raise DmsfAccessError if @file.locked_for_user?
    @project = @file.project
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
      @target_folder = DmsfFolder.visible.find(params[:target_folder_id])
      raise ActiveRecord::RecordNotFound unless DmsfFolder.visible.where(id: params[:target_folder_id]).exists?
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_target_folder
    if (@target_folder && @target_folder == @file.dmsf_folder) ||
      (@target_folder.nil? && @file.dmsf_folder.nil? && @target_project == @file.project)
      flash[:error] = l(:error_target_folder_same)
      redirect_to action: :new, id: @file, target_project_id: @target_project.id, target_folder_id: @target_folder
      return
    end
    if (@target_folder && (@target_folder.locked_for_user? || !DmsfFolder.permissions?(@target_folder, false))) ||
        !@target_project.allows_to?(:file_manipulation)
      raise DmsfAccessError
    end
  rescue DmsfAccessError
    render_403
  end

end
