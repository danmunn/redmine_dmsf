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

# Rollback container
class DmsfFileContainerRollback < ActiveRecord::Migration[4.2]
  def up
    # Add system folder_flag to dmsf_folders
    add_column :dmsf_folders, :system, :boolean, null: false, default: false
    # Create necessary folders
    new_folder_ids = []
    description = 'Documents assigned to issues'
    DmsfFile.where(container_type: 'Issue').find_each do |file|
      issue = Issue.find_by(id: file.container_id)
      unless issue
        Rails.logger.error "Issue ##{file.container_id} not found"
        next
      end
      # Parent folder
      parent = DmsfFolder.where(project_id: issue.project.id, title: '.Issues', description: description).first
      unless parent
        parent = DmsfFolder.new
        parent.project_id = issue.project.id
        parent.title = '.Issues'
        parent.description = description
        parent.user_id = User.anonymous.id
        parent.save!
        new_folder_ids << parent.id
      end
      # Issue folder
      title = "#{issue.id} - #{DmsfFolder.get_valid_title(issue.subject)}"
      folder = DmsfFolder.find_by(project_id: issue.project.id, dmsf_folder_id: parent.id, title: title)
      unless folder
        folder = DmsfFolder.new
        folder.project_id = issue.project.id
        folder.dmsf_folder_id = parent.id
        folder.title = "#{issue.id} - #{DmsfFolder.get_valid_title(issue.subject)}"
        folder.user_id = User.anonymous.id
        folder.save!
      end
      new_folder_ids << folder.id
      # Move the file into the new folder
      file.dmsf_folder_id = folder.id
      # The save methos requires project_id
      class << file
        attr_accessor :project_id
      end
      file.save(validate: false)
    end
    # Make DB changes in dmsf_files
    change_table :dmsf_files, bulk: true do |t|
      t.remove_index %i[container_id container_type]
      t.remove :container_type
      t.rename :container_id, :project_id
      t.index :project_id
    end
    # Initialize system folder_flag to dmsf_folders
    DmsfFolder.where(id: new_folder_ids).update_all system: true
  end

  def down
    # dmsf_files
    file_folder_ids = DmsfFile.joins(:dmsf_folder).where(dmsf_folders: { system: true }).pluck(
      'dmsf_files.id, dmsf_folders.title'
    )
    change_table :dmsf_files, bulk: true do |t|
      t.remove_index(:project_id) if t.index_exists?(:project_id)
      t.rename :project_id, :container_id
      # Temporarily added for the save method
      t.column :project_id, :int, null: true
      t.column :container_type, :string, limit: 30, null: false, default: 'Project'
    end
    DmsfFile.update_all container_type: 'Project'
    file_folder_ids.each do |id, title|
      file = DmsfFile.find_by(id: id)
      next unless file && (title =~ /(^\d+) - .*/)

      file.container_id = Regexp.last_match(1).to_i
      file.container_type = 'Issue'
      file.save!
    end
    change_table :dmsf_files, bulk: true do |t|
      t.remove :project_id # temporarily added for the save method
      t.index(%i[container_id container_type]) unless t.index_exists?(%i[container_id container_type])
    end
    # dmsf_folders
    DmsfFolder.where(system: true).delete_all
    remove_column :dmsf_folders, :system
  end
end
