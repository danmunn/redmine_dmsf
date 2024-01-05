# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Folder permissions controller
class DmsfFolderPermissionsController < ApplicationController
  before_action :find_folder,
                only: %i[destroy new autocomplete_for_user],
                if: -> { params[:dmsf_folder_id].present? }
  before_action :find_project
  before_action :authorize
  before_action :permissions

  helper :dmsf

  def permissions
    render_403 unless DmsfFolder.permissions?(@dmsf_folder)
    true
  end

  def new
    @principals = users_for_new_users
  end

  def append
    @principals = Principal.where(id: params[:user_ids]).to_a
    head :ok if @principals.blank?
  end

  def autocomplete_for_user
    @principals = users_for_new_users
    respond_to do |format|
      format.js
    end
  end

  private

  def users_for_new_users
    scope = Principal.active.visible.member_of(@project).like(params[:q]).order(:type, :lastname)
    if @dmsf_folder
      users = @dmsf_folder.permissions_users
      if users.any?
        ids = users.collect(&:id)
        scope = scope.where.not(id: ids)
      end
    end
    scope.to_a
  end

  def find_project
    @project = Project.visible.find_by_param(params[:project_id])
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_folder
    @dmsf_folder = DmsfFolder.visible.find(params[:dmsf_folder_id])
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
