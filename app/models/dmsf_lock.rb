# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

require 'simple_enum'

# Lock
class DmsfLock < ApplicationRecord
  before_create :generate_uuid
  belongs_to :dmsf_file, foreign_key: 'entity_id', inverse_of: :locks
  belongs_to :dmsf_folder, foreign_key: 'entity_id', inverse_of: :locks
  belongs_to :user

  # At the moment apparently we're only supporting a write lock?
  as_enum :lock_type, %i[type_write type_other]
  as_enum :lock_scope, %i[scope_exclusive scope_shared]

  # We really loosely bind the value in the belongs_to above
  # here we just ensure the data internal to the model is correct
  # to ensure everything lists fine - it's the same as a join
  # just without running the join in the first place
  def dmsf_file
    entity_type.zero? ? super : nil
  end

  # See the file, exact same scenario
  def dmsf_folder
    entity_type == 1 ? super : nil
  end

  def expired?
    expires_at && (expires_at <= Time.current)
  end

  def generate_uuid
    self.uuid = UUIDTools::UUID.random_create.to_s
  end

  # Let's allow our UUID to be searchable
  def self.find(*args)
    if args&.first.is_a?(String) && !args.first.match(/^\d*$/)
      lock = find_by_uuid(*args)
      raise ActiveRecord::RecordNotFound, "Couldn't find lock with uuid = #{args.first}" if lock.nil?

      lock
    else
      super
    end
  end

  def self.find_by_param(...)
    find(...)
  end
end
