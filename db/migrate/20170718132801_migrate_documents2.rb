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

require File.expand_path('../20170418104901_migrate_documents', __FILE__)

class MigrateDocuments2 < ActiveRecord::Migration

  # Copy of 20170418104901_migrate_documents.rb
  # Due to an error it might have happened that not all files have been migrated.
  # So, let's run the migration again

  def up
    # Migrate all documents from dmsf/p_{project identifier} to dmsf/{year}/{month}
    migration = MigrateDocuments.new
    migration.up
  end

  def down
    # Migrate all documents from dmsf/{year}/{month} to dmsf/p_{project identifier}
    migration = MigrateDocuments.new
    migration.down
  end

end
