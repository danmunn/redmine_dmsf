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

# Modify column
class ChangeRevisionDigestLimitTo64 < ActiveRecord::Migration[4.2]
  def up
    change_column :dmsf_file_revisions, :digest, :string, limit: 64
  end

  def down
    # Mysql2::Error: Data too long for column 'digest'
    # Recalculation of checksums for all revisions is technically possible but costs are to high.
    # change_column :dmsf_file_revisions, :digest, :string, limit: 40
  end
end
