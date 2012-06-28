# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012 Daniel Munn <dan.munn@munnster.co.uk>
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

class Dmsf144 < ActiveRecord::Migration


  class DmsfFileLock < ActiveRecord::Base
    belongs_to :file, :class_name => "DmsfFile", :foreign_key => "dmsf_file_id"
    belongs_to :user
  end  

  def self.up

    #Add our entity_type column (used with our entity type)
    add_column :dmsf_file_locks, :entity_type, :integer, :null => true

    #Add our lock relevent columns (ENUM) - null (till we upgrade data)
    add_column :dmsf_file_locks, :lock_type_cd, :integer, :null => true
    add_column :dmsf_file_locks, :lock_scope_cd, :integer, :null => true

    #Add our expires_at column
    add_column :dmsf_file_locks, :expires_at, :datetime, :null => true

    do_not_delete = []
    DmsfFileLock.order('updated_at DESC').group('dmsf_file_id').find_each do |lock|
      if (lock.locked)
        do_not_delete << lock.id
      end
    end

    say "Preserving #{do_not_delete.count} file lock(s) found in old schema"

    DmsfFileLock.delete_all(['id NOT IN (?)', do_not_delete])

    say "Applying default lock scope / type - Exclusive / Write"
    DmsfFileLock.update_all ['entity_type = ?, lock_type_cd = ?, lock_scope_cd = ?', 0, 0, 0]

    #These are not null-allowed columns
    change_column :dmsf_file_locks, :entity_type, :integer, :null => false
    change_column :dmsf_file_locks, :lock_type_cd, :integer, :null => false
    change_column :dmsf_file_locks, :lock_scope_cd, :integer, :null => false

    #Data cleanup
    rename_column :dmsf_file_locks, :dmsf_file_id, :entity_id
    remove_column :dmsf_file_locks, :locked
    rename_table :dmsf_file_locks, :dmsf_locks

    #Not sure if this is the right place to do this, as its file manipulation, not database (stricly)
    begin
      DmsfFileRevision.visible.each {|rev|
        next if rev.project.nil?
        existing = "#{DmsfFile.storage_path}/#{rev.disk_filename}"
        new_path = rev.disk_file
        if File.exist?(existing)
          if File.exist?(new_path)
            rev.disk_filename = rev.new_storage_filename
            new_path = rev.disk_file
            rev.save!
          end
          FileUtils.mv(existing, new_path)
        end
      }
    rescue
      #Nothing here, we just dont want a migration to break
    end
  end

  def self.down

    rename_table :dmsf_locks, :dmsf_file_locks

    add_column :dmsf_file_locks, :locked, :boolean, :default => false, :null => false

    #Data cleanup - delete all expired locks, or any folder locks
    say "Removing all expired and/or folder locks"
    DmsfFileLock.delete_all ['expires_at < ? OR entity_type = 1', Time.now]

    say "Changing all records to be locked"
    DmsfFileLock.update_all ['locked = ?', true]

    rename_column :dmsf_file_locks, :entity_id, :dmsf_file_id

    remove_column :dmsf_file_locks, :entity_type
    remove_column :dmsf_file_locks, :lock_type_cd
    remove_column :dmsf_file_locks, :lock_scope_cd
    remove_column :dmsf_file_locks, :expires_at

    #Not sure if this is the right place to do this, as its file manipulation, not database (stricly)
    begin
      DmsfFileRevision.visible.each {|rev|
        next if rev.project.nil?
        project = rev.project.identifier.gsub(/[^\w\.\-]/,'_')
        existing = "#{DmsfFile.storage_path}/p_#{project}/#{rev.disk_filename}"
        new_path = "#{DmsfFile.storage_path}/#{rev.disk_filename}"
        if File.exist?(existing)
          if File.exist?(new_path)
            rev.disk_filename = rev.new_storage_filename
            rev.save!
            new_path = "#{DmsfFile.storage_path}/#{rev.disk_filename}"
          end
          FileUtils.mv(existing, new_path)
        end
      }
    rescue
      #Nothing here, we just dont want a migration to break
    end
  end

end
