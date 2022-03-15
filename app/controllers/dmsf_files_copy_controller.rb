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

class DmsfFilesCopyController < ApplicationController

  menu_item :dmsf

  before_action :find_file
  before_action :authorize
  before_action :find_target_folder
  before_action :check_target_folder, only: [:copy, :move]

  accept_api_auth :copy, :move

  helper :dmsf

  def new
    member = Member.find_by(project_id: @project.id, user_id: User.current.id)
    @fast_links = member && member.dmsf_fast_links
    unless @fast_links
      @projects = DmsfFile.allowed_target_projects_on_copy
      @folders = DmsfFolder.directory_tree(@target_project, @folder)
    end
    @back_url = params[:back_url]
    render layout: !request.xhr?
  end

  def copy
    new_file = @file.copy_to(@target_project, @target_folder)
    failure = new_file.nil? || new_file.errors.present?
    if failure
      flash[:error] = new_file ? new_file.errors.full_messages.to_sentence : @file.errors.full_messages.to_sentence
    else
      flash[:notice] = l(:notice_successful_update)
    end
    respond_to do |format|
      format.html do
        redirect_back_or_default dmsf_folder_path(id: @file.project, folder_id: @file.dmsf_folder)
      end
      format.api do
        if failure
          render_validation_errors(new_file ? new_file : @file)
        else
          render_api_ok
        end
      end
    end
  end

  def move
    success = @file.move_to(@target_project, @target_folder)
    if success
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = @file.errors.full_messages.to_sentence
    end
    respond_to do |format|
      format.html do
        redirect_back_or_default dmsf_folder_path(id: @file.project, folder_id: @file.dmsf_folder)
      end
      format.api do
        if success
          render_api_ok
        else
          render_validation_errors @file
        end
      end
    end
  end

private

  def find_file
    raise ActiveRecord::RecordNotFound unless DmsfFile.where(id: params[:id]).exists?
    @file = DmsfFile.visible.find params[:id]
    raise RedmineDmsf::Errors::DmsfAccessError if @file.locked_for_user?
    @project = @file.project
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  end

  def find_target_folder
    if params[:target_folder_id].present?
      target_folder_id = params[:target_folder_id]
    elsif params[:dmsf_file_or_folder] && params[:dmsf_file_or_folder][:target_folder_id].present?
      target_folder_id = params[:dmsf_file_or_folder][:target_folder_id]
    end
    @target_folder = DmsfFolder.visible.find(target_folder_id) if target_folder_id
    if params[:target_project_id].present?
      target_project_id = params[:target_project_id]
    elsif params[:dmsf_file_or_folder] && params[:dmsf_file_or_folder][:target_project_id].present?
      target_project_id = params[:dmsf_file_or_folder][:target_project_id]
    else
      target_project_id = @target_folder&.project_id
    end
    @target_project = target_project_id ? Project.visible.find(target_project_id) : @project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_target_folder
    if (@target_folder && @target_folder == @file.dmsf_folder) ||
      (@target_folder.nil? && @file.dmsf_folder.nil? && @target_project == @file.project)
      flash[:error] = l(:error_target_folder_same)
      redirect_to action: :new, id: @file, target_project_id: @target_project&.id, target_folder_id: @target_folder
      return
    end
    if (@target_folder && (@target_folder.locked_for_user? || !DmsfFolder.permissions?(@target_folder,
     false))) || !@target_project.allows_to?(:file_manipulation)
      raise RedmineDmsf::Errors::DmsfAccessError
    end
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  end

end
