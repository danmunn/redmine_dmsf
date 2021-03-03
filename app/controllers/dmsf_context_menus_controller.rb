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

class DmsfContextMenusController < ApplicationController

  helper :context_menus

  before_action :find_folder
  before_action :find_dmsf_file
  before_action :find_dmsf_folder

  def dmsf
    if @dmsf_file
      @locked = @dmsf_file.locked?
      @project = @dmsf_file.project
      @allowed = User.current.allowed_to? :file_manipulation, @project
      @unlockable = @allowed && @dmsf_file.unlockable? && (!@dmsf_file.locked_for_user? ||
          User.current.allowed_to?(:force_file_unlock, @project))
      @email_allowed = User.current.allowed_to?(:email_documents, @project)
    elsif @dmsf_folder
      @locked = @dmsf_folder.locked?
      @project = @dmsf_folder.project
      @allowed = User.current.allowed_to?(:folder_manipulation, @project)
      @unlockable = @allowed && @dmsf_folder.unlockable? && (!@dmsf_folder.locked_for_user?) &&
          User.current.allowed_to?(:force_file_unlock, @project)
      @email_allowed = User.current.allowed_to?(:email_documents, @project)
    elsif @dmsf_link # url link
      @locked = false
      @unlockable = false
      @project = @dmsf_link.project
      @allowed = User.current.allowed_to? :file_manipulation, @project
      @email_allowed = false
    else # multiple selection
      @project = get_project
      @locked = false
      @unlockable = false
      @allowed = User.current.allowed_to?(:file_manipulation, @project) &&
          User.current.allowed_to?(:folder_manipulation, @project)
      @email_allowed = User.current.allowed_to?(:email_documents, @project)
    end
    render layout: false
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def trash
    if @dmsf_file
      @project = @dmsf_file.project
      @allowed_restore = User.current.allowed_to? :file_manipulation, @project
      @allowed_delete = User.current.allowed_to? :file_delete, @project
    elsif @dmsf_folder
      @project = @dmsf_folder.project
      @allowed_restore = User.current.allowed_to? :folder_manipulation, @project
      @allowed_delete = @allowed_restore
    elsif @dmsf_link # url link
      @project = @dmsf_link.project
      @allowed_restore = User.current.allowed_to? :file_manipulation, @project
      @allowed_delete = User.current.allowed_to? :file_delete, @project
    else # multiple selection
    @project = get_project
      @allowed_restore = User.current.allowed_to?(:file_manipulation, @project) &&
          User.current.allowed_to?(:folder_manipulation, @project)
      @allowed_delete = User.current.allowed_to?(:file_delete, @project) &&
          User.current.allowed_to?(:folder_manipulation, @project)
    end
    render layout: false
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def get_project
    prj = nil
    params[:ids].each do |id|
      if id =~ /file-(\d+)/
        item = DmsfFile.find_by(id: $1)
      elsif id =~ /(file|url)-link-(\d+)/
        item = DmsfLink.find_by(id: $2)
      elsif id =~ /folder-(\d+)/
        item = DmsfFolder.find_by(id: $1)
      elsif id =~ /folder-link-(\d+)/
        item = DmsfLink.find_by(id: $1)
      end
      unless prj
        prj = item&.project
      else
        return nil if(prj != item.project)
      end
    end
    prj
  end

  def find_folder
    @folder = DmsfFolder.find params[:folder_id] if params[:folder_id].present?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_dmsf_file
    if (params[:ids].present? && (params[:ids].size == 1)) && (!@dmsf_folder)
      if params[:ids][0] =~ /file-(\d+)/
        @dmsf_file = DmsfFile.find_by(id: $1)
      elsif params[:ids][0] =~ /(file|url)-link-(\d+)/
        @dmsf_link = DmsfLink.find_by(id: $2)
        @dmsf_file = DmsfFile.find_by(id: @dmsf_link.target_id) if @dmsf_link && (@dmsf_link.target_type != 'DmsfUrl')
      end
    end
  end

  def find_dmsf_folder
    if (params[:ids].present? && (params[:ids].size == 1)) && (!@dmsf_file)
      if params[:ids][0] =~ /folder-(\d+)/
        @dmsf_folder = DmsfFolder.find_by(id: $1)
      elsif params[:ids][0] =~ /folder-link-(\d+)/
        @dmsf_link = DmsfLink.find_by(id: $1)
        @dmsf_folder = DmsfFolder.find_by(id: @dmsf_link.target_id) if @dmsf_link
      end
    end
  end

end