# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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

  def dmsf
    selected_files = params[:files] || []
    selected_file_links = params[:file_links] || []
    if selected_file_links.present?
      selected_file_links.each do |id|
        link = DmsfLink.find_by_id id
        selected_files << link.target_id if link && !selected_files.include?(link.target_id.to_s)
      end
    end
    if selected_files.size == 1
      @file = DmsfFile.find selected_files[0]
    end
    render :layout => false
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end