# encode: utf-8
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
#

# File revision access query
class DmsfFileRevisionAccessQuery < Query
  attr_accessor :revision_id

  self.queried_class = DmsfFileRevisionAccess
  self.view_permission = :view_dmsf_files

  # Standard columns
  self.available_columns = [
    QueryColumn.new(:user, frozen: true),
    QueryColumn.new(:count, frozen: true),
    QueryColumn.new(:first_at, frozen: true),
    QueryColumn.new(:last_at, frozen: true)
  ]

  def initialize(attributes = nil, *_args)
    super attributes
    self.sort_criteria = []
    self.filters = {}
  end

  ######################################################################################################################
  # Inherited
  #

  def base_scope
    @scope ||= DmsfFileRevisionAccess.where(dmsf_file_revision_id: revision_id)
    @scope
  end

  # Returns the issue count
  def access_count
    base_scope
      .group(:user_id)
      .count.size
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid, e.message
  end

  def type
    'DmsfFileRevisionAccessQuery'
  end

  def available_columns
    @available_columns ||= self.class.available_columns.dup
    @available_columns
  end

  ######################################################################################################################
  # New

  def accesses(options = {})
    base_scope
      .access_grouped
      .joins(:user)
      .order(Arel.sql('COUNT(*) DESC'))
      .limit(options[:limit])
      .offset(options[:offset])
  end
end
