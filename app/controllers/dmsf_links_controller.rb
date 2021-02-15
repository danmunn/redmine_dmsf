# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
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

class DmsfLinksController < ApplicationController

  model_object DmsfLink

  before_action :find_model_object, only: [:destroy, :restore]
  before_action :find_link_project
  before_action :find_folder, only: [:destroy]
  before_action :authorize
  before_action :permissions

  protect_from_forgery except: :new

  accept_api_auth :create

  def permissions
    if @dmsf_link
      render_403 unless DmsfFolder.permissions?(@dmsf_link.dmsf_folder)
    end
    true
  end

  def initialize
    @dmsf_link = nil
    @target_folder_id = nil
    super
  end

  def new
    @dmsf_link = DmsfLink.new
    member = Member.find_by(project_id: params[:project_id], user_id: User.current.id)
    @fast_links = member && member.dmsf_fast_links
    @dmsf_link.project_id = params[:project_id]
    @dmsf_link.dmsf_folder_id = params[:dmsf_folder_id]
    @dmsf_file_id = params[:dmsf_file_id]
    @type = params[:type]
    @dmsf_link.target_project_id = params[:project_id]
    @target_folder_id = params[:dmsf_folder_id].to_i if params[:dmsf_folder_id].present?
    if @type == 'link_to'
      if @dmsf_file_id
        names = DmsfFile.where(id: @dmsf_file_id).pluck(:name)
        @dmsf_link.name = names.first if names.any?
      else
        titles = DmsfFolder.where(id: @target_folder_id).pluck(:title)
        @dmsf_link.name = titles.first if titles.any?
      end
    end
    @container = params[:container]
    respond_to do |format|
      format.html
      format.js
    end
  end

  def autocomplete_for_project
    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_folder
    respond_to do |format|
      format.js
    end
  end

  def create
    @dmsf_link = DmsfLink.new
    @dmsf_link.user = User.current
    if params[:dmsf_link][:type] == 'link_from'
      # Link from
      if params[:dmsf_link][:container].blank?
        @dmsf_link.project_id = params[:dmsf_link][:project_id]
        @dmsf_link.dmsf_folder_id = params[:dmsf_link][:dmsf_folder_id]
      else
        # A container link
        @dmsf_link.project_id = -1
        @dmsf_link.dmsf_folder_id = nil
      end
      @dmsf_link.target_project_id = params[:dmsf_link][:target_project_id]
      if params[:external_link] == 'true'
        @dmsf_link.external_url = params[:dmsf_link][:external_url]
        @dmsf_link.target_type = 'DmsfUrl'
      elsif params[:dmsf_link][:target_file_id].present?
        @dmsf_link.target_id = params[:dmsf_link][:target_file_id]
        @dmsf_link.target_type = DmsfFile.model_name.to_s
      else
        @dmsf_link.target_id = DmsfLinksHelper.is_a_number?(
          params[:dmsf_link][:target_folder_id]) ? params[:dmsf_link][:target_folder_id].to_i : nil
        @dmsf_link.target_type = DmsfFolder.model_name.to_s
      end
      @dmsf_link.name = params[:dmsf_link][:name]
      result = @dmsf_link.save
      if result
        flash[:notice] = l(:notice_successful_create)
      else
        msg = @dmsf_link.errors.full_messages.to_sentence
        flash[:error] = msg
        Rails.logger.error msg
      end
    else
      # Link to
      @dmsf_link.dmsf_folder_id = DmsfLinksHelper.is_a_number?(
        params[:dmsf_link][:target_folder_id]) ? params[:dmsf_link][:target_folder_id].to_i : nil
      if params[:dmsf_link][:target_project_id].present?
        @dmsf_link.project_id = params[:dmsf_link][:target_project_id]
      else
        project_ids = DmsfFolder.where(id: params[:dmsf_link][:target_folder_id]).pluck(:project_id)
        unless project_ids.any?
          render_404
          return
        end
        @dmsf_link.project_id = project_ids.first
      end
      @dmsf_link.target_project_id = params[:dmsf_link][:project_id]
      if params[:dmsf_link][:dmsf_file_id].present?
        @dmsf_link.target_id = params[:dmsf_link][:dmsf_file_id]
        @dmsf_link.target_type = DmsfFile.model_name.to_s
      else
        @dmsf_link.target_id = params[:dmsf_link][:dmsf_folder_id]
        @dmsf_link.target_type = DmsfFolder.model_name.to_s
      end
      @dmsf_link.name = params[:dmsf_link][:name]
      result = @dmsf_link.save
      if result
        flash[:notice] = l(:notice_successful_create)
      else
        flash[:error] = @dmsf_link.errors.full_messages.to_sentence
      end
    end
    respond_to do |format|
      format.html {
        if params[:dmsf_link][:type] == 'link_from'
          redirect_to dmsf_folder_path(id: @project, folder_id: @dmsf_link.dmsf_folder_id)
        else
          if params[:dmsf_link][:dmsf_file_id].present?
            redirect_to dmsf_file_path(@dmsf_link.target_file)
          else
            folder = @dmsf_link.target_folder.dmsf_folder if @dmsf_link.target_folder
            redirect_to dmsf_folder_path(id: @project, folder_id: folder)
          end
        end
      }
      format.api { render_validation_errors(@dmsf_link) unless result }
      format.js
    end
  end

  def destroy
    begin
    if @dmsf_link
      commit = params[:commit] == 'yes'
      if @dmsf_link.delete(commit)
        flash[:notice] = l(:notice_successful_delete)
      else
        flash[:error] = @dmsf_link.errors.full_messages.to_sentence
      end
    end
    rescue => e
      errors[:base] << e.message
      return false
    end
    redirect_back fallback_location: dmsf_folder_path(id: @project, folder_id: @folder)
  end

  def restore
    if @dmsf_link.restore
      flash[:notice] = l(:notice_dmsf_link_restored)
    end
    redirect_to :back
  end

  private

  def l_params
    params.fetch(:dmsf_link, {}).permit(:project_id)
  end

  def find_link_project
    if @dmsf_link
      @project = @dmsf_link.project
    else
      if params[:dmsf_link].present?
        if params[:dmsf_link].fetch(:project_id, nil).blank?
          pid = params[:dmsf_link].fetch(:target_project_id, nil)
        else
          pid = params[:dmsf_link][:project_id]
        end
      else
        pid = params[:project_id]
      end
      @project = Project.find(pid)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_folder
    @folder = DmsfFolder.find params[:folder_id] if params[:folder_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
