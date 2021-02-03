# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

class DmsfWorkflowNameValidator  < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if record.project_id
      if record.id
        if DmsfWorkflow.where(['(project_id IS NULL OR (project_id = ? AND id != ?)) AND name = ?',
                                record.project_id, record.id, value]).exists?
          record.errors.add attribute, :taken
        end
      else
        if DmsfWorkflow.where(['(project_id IS NULL OR project_id = ?) AND name = ?', record.project_id, value]).exists?
          record.errors.add attribute, :taken
        end
      end
    else
      if record.id
        if DmsfWorkflow.where(['name = ? AND id != ?', value, record.id]).exists?
          record.errors.add attribute, :taken
        end
      else
        if DmsfWorkflow.where(name: value).exists?
          record.errors.add attribute, :taken
        end
      end
    end
  end

end