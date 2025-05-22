# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

# Add column
class Dmsf090 < ActiveRecord::Migration[4.2]
  def up
    if defined?(EasyExtensions)
      add_column :members, :dmsf_mail_notification, :boolean, default: false
    else
      add_column :members, :dmsf_mail_notification, :boolean,
                 null: false, default: false
    end
    drop_table :dmsf_user_prefs
  end

  def down
    remove_column :members, :dmsf_mail_notification
    create_table :dmsf_user_prefs do |t|
      t.references :project, null: false
      t.references :user, null: false
      t.boolean :email_notify, null: false, default: false
      t.timestamps
    end
  end
end
