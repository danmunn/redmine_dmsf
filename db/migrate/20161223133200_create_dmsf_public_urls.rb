# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

# Create table
class CreateDmsfPublicUrls < ActiveRecord::Migration[4.2]
  def change
    create_table :dmsf_public_urls do |t|
      t.string :token, null: false, limit: 32
      t.references :dmsf_file, null: false
      t.references :user, null: false
      t.datetime :expire_at, null: false
      t.timestamps
    end
    add_index :dmsf_public_urls, :token
  end
end
