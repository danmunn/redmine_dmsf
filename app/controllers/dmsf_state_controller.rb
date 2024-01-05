# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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

# State controller
class DmsfStateController < ApplicationController
  menu_item :dmsf

  before_action :find_project
  before_action :authorize

  def user_pref_save
    member = @project.members.find_by(user_id: User.current.id)
    if member
      member.dmsf_mail_notification = params[:email_notify]
      member.dmsf_title_format = params[:title_format]
      member.dmsf_fast_links = params[:fast_links].present?
      if format_valid?(member.dmsf_title_format) && member.save
        flash[:notice] = l(:notice_your_preferences_were_saved)
      else
        flash[:error] = l(:notice_your_preferences_were_not_saved)
      end
    else
      flash[:warning] = l(:user_is_not_project_member)
    end
    if Setting.plugin_redmine_dmsf['dmsf_act_as_attachable']
      @project.update dmsf_act_as_attachable: params[:act_as_attachable]
    end
    @project.update default_dmsf_query_id: params[:default_dmsf_query]
    redirect_to settings_project_path(@project, tab: 'dmsf')
  end

  private

  def format_valid?(format)
    format.blank? || (/%(t|d|v|i|r)/.match?(format) && format.length < 256)
  end
end
