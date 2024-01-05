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

# File revision access
class DmsfFileRevisionAccess < ApplicationRecord
  belongs_to :dmsf_file_revision
  belongs_to :user

  delegate :dmsf_file, to: :dmsf_file_revision, allow_nil: false
  delegate :project, to: :dmsf_file, allow_nil: false

  scope :access_grouped,
        lambda {
          select('user_id, COUNT(*) AS count, MIN(created_at) AS first_at, MAX(created_at) AS last_at').group('user_id')
        }

  DOWNLOAD_ACTION = 0
  EMAIL_ACTION = 1

  acts_as_event(
    title: proc { |ra| "#{l(:label_dmsf_downloaded)}: #{ra.dmsf_file.dmsf_path_str}" },
    url: proc { |ra| { controller: 'dmsf_files', action: 'show', id: ra.dmsf_file } },
    datetime: proc { |ra| ra.updated_at },
    description: proc { |ra| ra.dmsf_file_revision.comment },
    author: proc { |ra| ra.user }
  )

  acts_as_activity_provider(
    type: 'dmsf_file_revision_accesses',
    timestamp: "#{DmsfFileRevisionAccess.table_name}.updated_at",
    author_key: "#{DmsfFileRevisionAccess.table_name}.user_id",
    permission: :view_dmsf_file_revision_accesses,
    scope: proc {
      DmsfFileRevisionAccess
        .joins(:dmsf_file_revision)
        .joins("JOIN #{DmsfFile.table_name} ON dmsf_files.id = dmsf_file_revisions.dmsf_file_id")
        .joins("JOIN #{Project.table_name} on dmsf_files.project_id = projects.id")
        .where(dmsf_files: { deleted: DmsfFile::STATUS_ACTIVE })
    }
  )
end
