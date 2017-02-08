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

class ApprovalWorkflowStdFields < ActiveRecord::Migration
  def self.up
    add_column :dmsf_workflows, :updated_on, :timestamp
    add_column :dmsf_workflows, :created_on, :datetime
    add_column :dmsf_workflows, :author_id, :integer
    DmsfWorkflow.reset_column_information
    # Set updated_on
    DmsfWorkflow.all.each(&:touch)
    # Set created_on and author_id
    DmsfWorkflow.update_all 'created_on = updated_on, author_id = (select id from users where admin limit 1)'
  end

  def self.down
    remove_column :dmsf_workflows, :updated_on
    remove_column :dmsf_workflows, :created_on
    remove_column :dmsf_workflows, :author_id
  end
end