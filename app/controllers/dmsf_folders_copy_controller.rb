# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
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

  accept_api_auth :copy, :move

  helper :dmsf

  def new
    member = Member.find_by(project_id: @project.id, user_id: User.current.id)
    @fast_links = member && member.dmsf_fast_links
    unless @fast_links
      @projects = DmsfFolder.allowed_target_projects_on_copy
      @folders = DmsfFolder.directory_tree(@target_project, @folder)
      @target_folder = DmsfFolder.visible.find(params[:target_folder_id]) unless params[:target_folder_id].blank?
    end
    @back_url = params[:back_url]
    render layout: !request.xhr?
  end

  def copy
    new_folder = @folder.copy_to(@target_project, @target_folder)
    success = new_folder.errors.empty?
    if success
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = new_folder.errors.full_messages.to_sentence
    end
    respond_to do |format|
      format.html do
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder.dmsf_folder)
      end
      format.api do
        if success
          render_api_ok
        else
          render_validation_errors new_folder
        end
      end
    end
  end

  def move
    success = @folder.move_to(@target_project, @target_folder)
    if success
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = @folder.errors.full_messages.to_sentence
    end
    respond_to do |format|
      format.html do
        redirect_back_or_default dmsf_folder_path(id: @project, folder_id: @folder.dmsf_folder)
      end
      format.api do
        if success
          render_api_ok
        else
          render_validation_errors @folder
        end
      end
    end
  end

  private

  def find_folder
    raise ActiveRecord::RecordNotFound unless DmsfFolder.where(id: params[:id]).exists?
    @folder = DmsfFolder.visible.find params[:id]
    raise RedmineDmsf::Errors::DmsfAccessError if @folder.locked_for_user?
    @project = @folder.project
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  end

  def find_target_folder
    if params[:dmsf_file_or_folder] && params[:dmsf_file_or_folder][:target_project_id].present?
      @target_project = Project.find params[:dmsf_file_or_folder][:target_project_id]
    else
      @target_project = @project
    end
    if params[:dmsf_file_or_folder] && params[:dmsf_file_or_folder][:target_folder_id].present?
      target_folder_id = params[:dmsf_file_or_folder][:target_folder_id]
      @target_folder = DmsfFolder.find(target_folder_id)
      raise ActiveRecord::RecordNotFound unless DmsfFolder.visible.where(id: target_folder_id).exists?
      @target_project = @target_folder&.project
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
      raise RedmineDmsf::Errors::DmsfAccessError
    end
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  end

end
