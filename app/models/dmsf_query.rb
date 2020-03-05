# encode: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
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

class DmsfQuery < Query

  attr_accessor :dmsf_folder_id, :deleted

  self.queried_class = DmsfFolder
  self.view_permission = :view_dmsf_files

  # Standard columns
  self.available_columns = [
      QueryColumn.new(:id, sortable: 'id', caption: '#'),
      DmsfTitleQueryColumn.new(:title, sortable: 'title', frozen: true),
      QueryColumn.new(:size, sortable: 'size'),
      DmsfModifiedQueryColumn.new(:modified, sortable: 'updated'),
      DmsfVersionQueryColumn.new(:version, sortable: 'major_version, minor_version'),
      QueryColumn.new(:workflow, sortable: 'workflow'),
      QueryColumn.new(:author, sortable: 'firstname, lastname')
  ]

  def initialize(attributes)
    super attributes
    self.sort_criteria = []
    self.filters = {}
  end

  ######################################################################################################################
  # Inherited
  #

  def available_columns
    unless @available_columns
      @available_columns = self.class.available_columns.dup
      @available_columns += DmsfFileRevisionCustomField.visible.collect do |cf|
        c = QueryCustomFieldColumn.new(cf)
        # We would like to prevent grouping in the Option form
        c.groupable = false
        c
      end
    end
    @available_columns
  end

  def default_columns_names
    unless @default_column_names
      @default_column_names = []
      columns = available_columns
      if columns
        columns.each do |column|
          if DmsfFolder.is_column_on?(column.name.to_s)
            @default_column_names << column.name.to_sym
          end
        end
      end
    end
    @default_column_names
  end

  def default_sort_criteria
    [['title', 'ASC']]
  end

  def base_scope
    unless @scope
      @scope = [dmsf_folders_scope, dmsf_folder_links_scope, dmsf_files_scope, dmsf_file_links_scope, dmsf_url_links_scope].
          inject(:union_all)
    end
    @scope
  end

  # Returns the issue count
  def dmsf_count
    base_scope.
        where(statement).
        count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def type
    'DmsfQuery'
  end

  def initialize_available_filters
    add_available_filter 'author', type: :list, values: lambda { author_values }
    add_available_filter 'title', type: :text
    add_available_filter 'updated', type: :date_past
    add_custom_fields_filters(DmsfFileRevisionCustomField.all)
  end

  def statement
    unless @statement
      filters_clauses = []
      filters.each_key do |field|
        v = values_for(field).clone
        next unless v and !v.empty?
        operator = operator_for(field)
        if field == 'author'
          if v.delete('me')
              v.push(User.current.id.to_s)
          end
        end
        filters_clauses << '(' + sql_for_field(field, operator, v, queried_table_name, field) + ')'
      end
      filters_clauses.reject!(&:blank?)
      if filters_clauses.any?
        @statement = filters_clauses.join(' AND ').
            gsub("#{queried_class.table_name}.", '')
        DmsfFileRevisionCustomField.visible.pluck(:id, :name).each do |id, name|
          @statement.gsub!("cf_#{id}", "\"#{name}\"")
        end
        end
    end
    @statement
  end

  ######################################################################################################################
  # New

  def dmsf_nodes(options={})
    order_option = ['sort', group_by_sort_order, (options[:order] || sort_clause[0]), 'title'].flatten.reject(&:blank?)
    if order_option.size > 2
      DmsfFileRevisionCustomField.visible.pluck(:id, :name).each do |id, name|
        order_option[1].gsub!("COALESCE(cf_#{id}.value, '')", "\"#{name}\"")
      end
      order_option[1].gsub!(',', " #{$1},")
      if order_option[1] =~ /(DESC|ASC)$/
        order_option[1].gsub!(',', " #{$1},")
      end
    end

    base_scope.
        where(statement).
        order(order_option).
        limit(options[:limit]).
        offset(options[:offset])
  end

  def extra_columns
    []
  end

  private

  def dmsf_folders_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_folders.id) AS \"#{name}\""
    end
    scope = DmsfFolder.
        select(%{
          dmsf_folders.id AS id,
          dmsf_folders.project_id AS project_id,
          CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS revision_id,
          dmsf_folders.title AS title,
          NULL AS filename,
          CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
          dmsf_folders.updated_at AS updated,
          NULL AS major_version,
          NULL AS minor_version,
          NULL AS workflow,
          NULL AS workflow_id,
          users.firstname AS firstname,
          users.lastname AS lastname,
          users.id AS author,
          'folder' AS type,
          dmsf_folders.deleted AS deleted,
          0 AS sort #{cf_columns}}).
        joins('LEFT JOIN users ON dmsf_folders.user_id = users.id').
        visible(!deleted)
    if deleted
      scope.where(dmsf_folders: { project_id: project.id, deleted: deleted })
    else
      scope.where(dmsf_folders: { project_id: project.id, dmsf_folder_id: dmsf_folder_id, deleted: deleted })
    end
  end

  def dmsf_folder_links_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_folders.id) AS \"#{name}\""
    end
    scope = DmsfLink.
        select(%{
          dmsf_links.id AS id,
          COALESCE(dmsf_folders.project_id, dmsf_links.project_id) AS project_id,
          CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS revision_id,
          dmsf_links.name AS title,
          dmsf_folders.title AS filename,
          CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
          COALESCE(dmsf_folders.updated_at, dmsf_links.updated_at) AS updated,
          NULL AS major_version,
          NULL AS minor_version,
          NULL AS workflow,
          NULL AS workflow_id,
          users.firstname AS firstname,
          users.lastname AS lastname,
          users.id AS author,
          'folder-link' AS type,
          dmsf_links.deleted AS deleted,
          0 AS sort #{cf_columns}}).
        joins('LEFT JOIN dmsf_folders ON dmsf_links.target_id = dmsf_folders.id').
        joins('LEFT JOIN users ON users.id = COALESCE(dmsf_folders.user_id, dmsf_links.user_id)')
    if deleted
      scope.where(dmsf_links: { target_type: 'DmsfFolder', project_id: project.id, deleted: deleted })
    else
      scope.where(dmsf_links: { target_type: 'DmsfFolder', project_id: project.id, dmsf_folder_id: dmsf_folder_id,
                          deleted: deleted })
    end
  end

  def dmsf_files_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_files.id) AS \"#{name}\""
    end
    scope = DmsfFile.
        select(%{
          dmsf_files.id AS id,
          dmsf_files.project_id AS project_id,
          dmsf_file_revisions.id AS revision_id,
          dmsf_file_revisions.title AS title,
          dmsf_file_revisions.name AS filename,
          dmsf_file_revisions.size AS size,
          dmsf_file_revisions.updated_at AS updated,
          dmsf_file_revisions.major_version AS major_version,
	        dmsf_file_revisions.minor_version AS minor_version,
          dmsf_file_revisions.workflow AS workflow,
          dmsf_file_revisions.dmsf_workflow_id AS workflow_id,
          users.firstname AS firstname,
          users.lastname AS lastname,
          users.id AS author,
          'file' AS type,
          dmsf_files.deleted AS deleted,
          1 AS sort #{cf_columns}}).
        joins(:dmsf_file_revisions).
        joins('LEFT JOIN users ON dmsf_file_revisions.user_id = users.id ').
        where('dmsf_file_revisions.created_at = (SELECT MAX(r.created_at) FROM dmsf_file_revisions r WHERE r.dmsf_file_id = dmsf_file_revisions.dmsf_file_id)')
    if deleted
      scope.where(dmsf_files: { project_id: project.id, deleted: deleted })
    else
      scope.where(dmsf_files: { project_id: project.id, dmsf_folder_id: dmsf_folder_id, deleted: deleted })
    end
  end

  def dmsf_file_links_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_files.id) AS \"#{name}\""
    end
    scope = DmsfLink.
        select(%{
          dmsf_links.id AS id,
          dmsf_files.project_id AS project_id,
          dmsf_file_revisions.id AS revision_id,
          dmsf_links.name AS title,
          dmsf_file_revisions.name AS filename,
          dmsf_file_revisions.size AS size,
          dmsf_file_revisions.updated_at AS updated,
          dmsf_file_revisions.major_version AS major_version,
	        dmsf_file_revisions.minor_version AS minor_version,
          dmsf_file_revisions.workflow AS workflow,
          dmsf_file_revisions.dmsf_workflow_id AS workflow_id,
          users.firstname AS firstname,
          users.lastname AS lastname,
          users.id AS author,
          'file-link' AS type,
          dmsf_links.deleted AS deleted,
          1 AS sort #{cf_columns}}).
        joins('JOIN dmsf_files ON dmsf_files.id = dmsf_links.target_id').
        joins('JOIN dmsf_file_revisions ON dmsf_file_revisions.dmsf_file_id = dmsf_files.id').
        joins('LEFT JOIN users ON dmsf_file_revisions.user_id = users.id ').
        where('dmsf_file_revisions.created_at = (SELECT MAX(r.created_at) FROM dmsf_file_revisions r WHERE r.dmsf_file_id = dmsf_file_revisions.dmsf_file_id)')
    if deleted
      scope.where(project_id: project.id, deleted: deleted)
    else
      scope.where(project_id: project.id, dmsf_folder_id: dmsf_folder_id, deleted: deleted)
    end
  end

  def dmsf_url_links_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:name).each do |name|
      cf_columns << ",NULL AS \"#{name}\""
    end
    scope = DmsfLink.
        select(%{
          dmsf_links.id AS id,
          dmsf_links.project_id AS project_id,
          CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS revision_id,
          dmsf_links.name AS title,
          dmsf_links.external_url AS filename,
          CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
          dmsf_links.updated_at AS updated,
	        NULL AS major_version,
          NULL AS minor_version,
          NULL AS workflow,
          NULL AS workflow_id,
          users.firstname AS firstname,
          users.lastname AS lastname,
          users.id AS author,
          'url-link' AS type,
          dmsf_links.deleted AS deleted,
          1 AS sort #{cf_columns}}).
        joins('LEFT JOIN users ON dmsf_links.user_id = users.id ')
    if deleted
      scope.where(target_type: 'DmsfUrl', project_id: project.id, deleted: deleted)
    else
      scope.where(target_type: 'DmsfUrl', project_id: project.id, dmsf_folder_id: dmsf_folder_id, deleted: deleted)
    end
  end

end
