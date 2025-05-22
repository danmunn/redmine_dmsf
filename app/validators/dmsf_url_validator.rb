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

# URL validator
class DmsfUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless record.target_type == 'DmsfUrl'

    begin
      if value.present?
        # https://www.google.com/search?q=寿司
        URI.parse value.split('?').first
      else
        record.errors.add attribute, :invalid
      end
    rescue URI::InvalidURIError => e
      record.errors.add attribute, :invalid
      Rails.logger.error e.message
    end
  end
end
