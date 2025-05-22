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

# remove column
class RemoveProjectFromRevision < ActiveRecord::Migration[4.2]
  def up
    remove_column :dmsf_file_revisions, :project_id
  end

  def down
    add_column :dmsf_file_revisions, :project_id, :integer, null: true
    DmsfFileRevision.reset_column_information
    DmsfFileRevision.find_each do |revision|
      if revision.dmsf_file
        revision.project_id = revision.dmsf_file.project.id
        revision.save!
      end
    end
  end
end
