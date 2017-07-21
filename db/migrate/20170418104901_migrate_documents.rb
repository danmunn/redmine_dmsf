# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

class MigrateDocuments < ActiveRecord::Migration

  def up
    # Migrate all documents from dmsf/p_{project identifier} to dmsf/{year}/{month}
    DmsfFileRevision.find_each do |dmsf_file_revision|
      if dmsf_file_revision.dmsf_file
        if dmsf_file_revision.dmsf_file.project
          origin = self.disk_file(dmsf_file_revision)
          if origin
            if File.exist?(origin)
              target = dmsf_file_revision.disk_file(false)
              if target
                unless File.exist?(target)
                  begin
                    FileUtils.mv origin, target, :verbose => true
                    folder = self.storage_base_path(dmsf_file_revision)
                    Dir.rmdir(folder) if (folder && (Dir.entries(folder).size == 2))
                  rescue Exception => e
                    say "DmsfFileRevisions ID #{dmsf_file_revision.id}: #{e.message}"
                  end
                else
                  say "DmsfFileRevisions ID #{dmsf_file_revision.id}: Target '#{target}' exists"
                end
              else
                say "DmsfFileRevisions ID #{dmsf_file_revision.id}: target = nil"
              end
            else
              say "DmsfFileRevisions ID #{dmsf_file_revision.id}: Origin '#{origin}' doesn't exist"
            end
          else
            say "DmsfFileRevisions ID #{dmsf_file_revision.id}: disk_file = nil"
          end
        else
          say "DmsfFile ID #{dmsf_file_revision.dmsf_file.id}: project = nil"
        end
      else
        say "DmsfFileRevisions ID #{dmsf_file_revision.id}: dmsf_file = nil"
      end
    end
  end

  def down
    # Migrate all documents from dmsf/{year}/{month} to dmsf/p_{project identifier}
    DmsfFileRevision.find_each do |dmsf_file_revision|
      if dmsf_file_revision.dmsf_file
        if dmsf_file_revision.dmsf_file.project
          origin = dmsf_file_revision.disk_file(false)
          if origin
            if File.exist?(origin)
              target = self.disk_file(dmsf_file_revision)
              if target
                unless File.exist?(target)
                  begin
                    FileUtils.mv origin, target, :verbose => true
                    folder = dmsf_file_revision.storage_base_path
                    Dir.rmdir(folder) if (folder && (Dir.entries(folder).size == 2))
                  rescue Exception => e
                    say "DmsfFileRevisions ID #{dmsf_file_revision.id}: #{e.message}"
                  end
                else
                  say "DmsfFileRevisions ID #{dmsf_file_revision.id}: Target '#{target}' exists"
                end
              else
                say "DmsfFileRevisions ID #{dmsf_file_revision.id}: target = nil"
              end
            else
              say "DmsfFileRevisions ID #{dmsf_file_revision.id}: Origin '#{origin}' doesn't exist"
            end
          else
            say "DmsfFileRevisions ID #{dmsf_file_revision.id}: disk_file = nil"
          end
        else
          say "DmsfFile ID #{dmsf_file_revision.dmsf_file.id}: project = nil"
        end
      else
        say "DmsfFileRevisions ID #{dmsf_file_revision.id}: dmsf_file = nil"
      end
    end
  end

  def storage_base_path(dmsf_file_revision)
    if dmsf_file_revision.dmsf_file
      if dmsf_file_revision.dmsf_file.project
        project_base = dmsf_file_revision.dmsf_file.project.identifier.gsub(/[^\w\.\-]/,'_')
        return "#{DmsfFile.storage_path}/p_#{project_base}"
      end
    end
    nil
  end

  def disk_file(dmsf_file_revision)
    path = storage_base_path(dmsf_file_revision)
    if path
      FileUtils.mkdir_p(path) unless File.exist?(path)
      return "#{path}/#{dmsf_file_revision.disk_filename}"
    end
    nil
  end

end
