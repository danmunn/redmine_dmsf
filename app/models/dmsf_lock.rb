# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012   Daniel Munn  <dan.munn@munnster.co.uk>
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

class DmsfLock < ActiveRecord::Base
  before_create :generate_uuid
  belongs_to :file, :class_name => 'DmsfFile', :foreign_key => 'entity_id'
  belongs_to :folder, :class_name => 'DmsfFolder', :foreign_key => 'entity_id'
  belongs_to :user

  #At the moment apparently we're only supporting a write lock?

  as_enum :lock_type, [:type_write, :type_other]
  as_enum :lock_scope, [:scope_exclusive, :scope_shared]
  
  # We really loosly bind the value in the belongs_to above
  # here we just ensure the data internal to the model is correct
  # to ensure everything lists fine - it's the same as a join
  # just without runing the join in the first place
  def file
    entity_type == 0 ? super : nil;
  end

  # see file, exact same scenario
  def folder
    entity_type == 1 ? super : nil;
  end

  def expired?
    return false if expires_at.nil?
    return expires_at <= Time.now
  end

  def generate_uuid
    self.uuid = UUIDTools::UUID.random_create.to_s
  end

  def self.delete_expired
    self.delete_all ["#{DmsfLock.table_name}.expires_at IS NOT NULL && #{DmsfLock.table_name}.expires_at < ?", Time.now]
  end

  #Lets allow our UUID to be searchable
  def self.find(*args)
    if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
      lock = find_by_uuid(*args)
      raise ActiveRecord::RecordNotFound, "Couldn't find lock with uuid=#{args.first}" if lock.nil?
      lock
    else
      super
    end
  end

  def self.find_by_param(*args)
    self.find(*args)
  end
  
end
