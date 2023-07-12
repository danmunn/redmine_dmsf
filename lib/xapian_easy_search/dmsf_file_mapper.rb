# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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

require 'xapian_easy_search/base_mapper'

module XapianEasySearch
  # DmsfFile mapper
  class DmsfFileMapper < XapianEasySearch::BaseMapper
    class << self
      def default_index_options
        super.merge(
          title: :name,
          updated_at: ->(dmsf_file) { dmsf_file&.last_revision&.updated_at },
          content: ->(dmsf_file) { dmsf_file&.content }
        )
      end

      def extend_query_filter
        proc do |query|
          # TODO: we filter the results with all files visible for the user. It's the worst way how to filter them.
          files = DmsfFile.visible
                          .joins('JOIN dmsf_file_revisions ON dmsf_file_revisions.dmsf_file_id = dmsf_files.id')
                          .joins(:project)
                          .where(Project.allowed_to_condition(User.current, :view_dmsf_files)).to_a
          files.delete_if { |f| !DmsfFolder.permissions?(f.dmsf_folder) }
          ids = files.map(&:id)
          Xapian::Query.new Xapian::Query::OP_AND, query, boolean_filter_query(:source_id, ids)
        end
      end
    end
  end
end

XapianEasySearch::DmsfFileMapper.attach if Redmine::Plugin.installed?('easy_extensions')
