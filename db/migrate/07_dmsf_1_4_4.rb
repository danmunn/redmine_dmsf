# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

require 'fileutils'
require 'uuidtools'

# Locking
class Dmsf144 < ActiveRecord::Migration[4.2]
  # File lock
  class DmsfFileLock < ApplicationRecord
    belongs_to :file, class_name: 'DmsfFile', foreign_key: 'dmsf_file_id'
    belongs_to :user
  end

  def up
    change_table :dmsf_file_locks, bulk: true do |t|
      # Add our entity_type column (used with our entity type)
      t.column :entity_type, :integer, null: true
      # Add our lock relevent columns (ENUM) - null (till we upgrade data)
      t.column :lock_type_cd, :integer, null: true
      t.column :lock_scope_cd, :integer, null: true
      t.column :uuid, :string, null: true, limit: 36
      # Add our expires_at column
      t.column :expires_at, :datetime, null: true
    end
    do_not_delete = []
    # - 2012-07-12: Better compatibility for postgres - query used 3 columns however
    #               only on appearing in group, find_each imposes a limit and incorrect
    #               ordering, so adapted that, we grab id's load a mock object, and reload
    #               data into it, which should enable us to run checks we need, not as
    #               efficient, however compatible across the board.
    DmsfFileLock.reset_column_information
    DmsfFileLock.select('MAX(id), id').order(Arel.sql('MAX(id) DESC')).group(:dmsf_file_id, :id).find do |lock|
      lock.reload
      do_not_delete << lock.id if lock.locked
    end
    # Generate new lock Id's for whats being persisted
    do_not_delete.each do |l|
      # Find the lock
      lock = DmsfFileLock.find(l)
      next unless lock

      lock.uuid = UUIDTools::UUID.random_create.to_s
      lock.save!
    end
    say "Preserving #{do_not_delete.count} file lock(s) found in old schema"
    DmsfFileLock.where.not(id: do_not_delete).delete_all
    # We need to force our newly found
    say 'Applying default lock scope / type - Exclusive / Write'
    DmsfFileLock.update_all entity_type: 0, lock_type_cd: 0, lock_scope_cd: 0
    change_table :dmsf_file_locks, bulk: true do |t|
      # These are not null-allowed columns
      t.change :entity_type, :integer, null: false
      t.change :lock_type_cd, :integer, null: false
      t.change :lock_scope_cd, :integer, null: false
      # Data cleanup
      t.rename :dmsf_file_id, :entity_id
      t.remove :locked
    end
    rename_table :dmsf_file_locks, :dmsf_locks
    # Not sure if this is the right place to do this, as its file manipulation, not database (strictly)
    say 'Completing one-time file migration ...'
    begin
      DmsfFileRevision.find_each do |rev|
        next unless rev.project

        existing = DmsfFile.storage_path.join rev.disk_filename
        new_path = rev.disk_file(search_if_not_exists: false)
        begin
          if File.exist?(existing)
            if File.exist?(new_path)
              rev.disk_filename = rev.new_storage_filename
              new_path = rev.disk_file(search_if_not_exists: false)
              rev.save!
            end
            # Ensure the project path exists
            project_directory = File.dirname(new_path)
            Dir.mkdir(project_directory) unless File.directory? project_directory
            FileUtils.mv existing, new_path
            say "Migration: #{existing} -> #{new_path} succeeded"
          end
        rescue StandardError => e # Here we wrap around IO in the loop to prevent one failure ruining complete run.
          say "Migration: #{existing} -> #{new_path} failed"
          Rails.logger.error e.message
        end
      end
      say 'Action was successful'
    rescue StandardError => e
      say 'Action was not successful'
      Rails.logger.error e.message # See issue #86
      # Nothing here, we just dont want a migration to break
    end
  end

  def down
    rename_table :dmsf_locks, :dmsf_file_locks
    add_column :dmsf_file_locks, :locked, :boolean, default: false, null: false
    # Data cleanup - delete all expired locks, or any folder locks
    DmsfFileLock.reset_column_information
    say 'Removing all expired and/or folder locks'
    DmsfFileLock.where(['expires_at < ? OR entity_type = 1', Time.current]).delete_all
    say 'Changing all records to be locked'
    DmsfFileLock.update_all locked: true
    change_table :dmsf_file_locks, bulk: true do |t|
      t.rename :entity_id, :dmsf_file_id
      t.remove :entity_type
      t.remove :lock_type_cd
      t.remove :lock_scope_cd
      t.remove :expires_at
      t.remove :uuid
    end
    # Not sure if this is the right place to do this, as its file manipulation, not database (stricly)
    begin
      say 'restoring old file-structure'
      DmsfFileRevision.find_each do |rev|
        next unless rev.project

        project = rev.project.identifier.gsub(/[^\w.\-]/, '_')
        existing = DmsfFile.storage_path.join("p_#{project}/#{rev.disk_filename}")
        new_path = DmsfFile.storage_path.join(rev.disk_filename)
        if File.exist?(existing)
          if File.exist?(new_path)
            rev.disk_filename = rev.new_storage_filename
            rev.save!
            new_path = DmsfFile.storage_path.join(rev.disk_filename)
          end
          FileUtils.mv existing, new_path
        end
      end
    rescue StandardError
      # Nothing here, we just dont want a migration to break
    end
  end
end
