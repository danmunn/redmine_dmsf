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

# Max file size validator
class DmsfMaxFileSizeValidator < ActiveModel::EachValidator
  include Redmine::I18n

  def validate_each(record, attribute, value)
    if value && (value > Setting.attachment_max_size.to_i.kilobytes)
      record.errors.add attribute,
                        l(:error_attachment_too_big, max_size: ActiveSupport::NumberHelper.number_to_human_size(
                          Setting.attachment_max_size.to_i.kilobytes
                        ))
      false
    else
      true
    end
  end
end
