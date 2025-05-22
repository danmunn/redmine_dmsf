# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

# Workflow name validator
class DmsfWorkflowNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.project_id
      if record.id
        if DmsfWorkflow.exists?(['(project_id IS NULL OR (project_id = ? AND id != ?)) AND name = ?',
                                 record.project_id,
                                 record.id, value])
          record.errors.add attribute, :taken
        end
      elsif DmsfWorkflow.exists?(['(project_id IS NULL OR project_id = ?) AND name = ?', record.project_id, value])
        record.errors.add attribute, :taken
      end
    elsif record.id
      record.errors.add attribute, :taken if DmsfWorkflow.exists?(['name = ? AND id != ?', value, record.id])
    elsif DmsfWorkflow.exists?(name: value)
      record.errors.add attribute, :taken
    end
  end
end
