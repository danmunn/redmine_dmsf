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

# Folders permissions helper
module DmsfFolderPermissionsHelper
  def users_checkboxes(users, inherited: false)
    s = []
    id = inherited ? 'inherited_permissions[user_ids][]' : 'permissions[user_ids][]'
    users.each do |user|
      content = check_box_tag(id, user.id, true, disabled: inherited, id: nil) + user.name
      s << content_tag(:label, content, id: "user_permission_ids_#{user.id}", class: 'inline')
    end
    safe_join s
  end

  def render_principals_for_new_folder_permissions(users)
    principals_check_box_tags 'user_ids[]', users
  end
end
