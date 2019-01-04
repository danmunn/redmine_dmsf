# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

  before_action :find_project
  before_action :find_folder
  before_action :find_file, :except => [:trash]

  def dmsf
    @disabled = params[:ids].blank?
    render :layout => false
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def trash
    render :layout => false
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def find_folder
    @folder = DmsfFolder.find params[:folder_id] if params[:folder_id].present?
  rescue DmsfAccessError
    render_403
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_file
    if params[:ids].present?
      selected_files = params[:ids].select{ |x| x =~ /file-\d+/ }.map{ |x| $1.to_i if x =~ /file-(\d+)/ }
      selected_file_links = params[:ids].select{ |x| x =~ /file-link-\d+/ }.map{ |x| $1.to_i if x =~ /file-link-(\d+)/ }
      selected_file_links.each do |id|
        target_id = DmsfLink.where(id: id).pluck(:target_id).first
        selected_files << target_id if target_id && !selected_files.include?(target_id)
      end
      if (selected_files.size == 1) && (params[:ids].size == 1)
        @file = DmsfFile.find_by(id: selected_files[0])
      end
    end
  end

end