# encode: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
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
#

class DmsfQuery < Query

  attr_accessor :dmsf_folder_id, :deleted

  self.queried_class = DmsfFolder
  self.view_permission = :view_dmsf_files

  # Standard columns
  self.available_columns = [
      QueryColumn.new(:id, sortable: 'id', caption: +'#'),
      DmsfTitleQueryColumn.new(:title, sortable: 'title', frozen: true),
      QueryColumn.new(:size, sortable: 'size'),
      DmsfModifiedQueryColumn.new(:modified, sortable: 'updated'),
      DmsfVersionQueryColumn.new(:version, sortable: 'major_version, minor_version', caption: :label_dmsf_version),
      QueryColumn.new(:workflow, sortable: 'workflow'),
      QueryColumn.new(:author, sortable: 'firstname, lastname')
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.sort_criteria = []
    self.filters ||= { 'title' => { operator: '~', values: ['']} }
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
      @scope = [dmsf_folders_scope, dmsf_folder_links_scope, dmsf_projects_scope, dmsf_files_scope,
                dmsf_file_links_scope, dmsf_url_links_scope].compact.inject(:union_all)
    end
    @scope
  end

  # Returns the issue count
  def dmsf_count
    base_scope.where(statement).count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new e.message
  end

  def type
    'DmsfQuery'
  end

  def initialize_available_filters
    add_available_filter 'author', type: :list, values: lambda { author_values }
    add_available_filter 'title', type: :text
    add_available_filter 'updated', type: :date_past
    add_custom_fields_filters DmsfFileRevisionCustomField.all
  end

  def statement
    unless @statement
      @filter_dmsf_folder_id = false
      filters_clauses = []
      filters.each_key do |field|
        v = values_for(field).clone
        next unless v and !v.empty?
        operator = operator_for(field)
        case field
        when 'author'
          if v.delete('me')
            v.push User.current.id.to_s
          end
        when 'title'
          next if v.include?('')
        end
        filters_clauses << '(' + sql_for_field(field, operator, v, queried_table_name, field) + ')'
      end
      filters_clauses.reject!(&:blank?)
      @statement = filters_clauses.any? ? filters_clauses.join(' AND ') : nil
    end
    @statement
  end

  def validate_query_filters
    # Skip validation for empty title (default filter)
    filter = filters.delete('title')
    super
    # Add it back
    filters['title'] = filter if filter
  end

  def columns
    cols = super
    # Just move the optional column Id to the beginning as it isn't frozen
    id_index = cols.index { |col| col.name == :id }
    if id_index == 1
      id_col = cols.delete_at(id_index)
      cols.insert 0, id_col
    end
    cols
  end

  ######################################################################################################################
  # New

  def dmsf_nodes(options={})
    order_option = ['sort', group_by_sort_order, (options[:order] || sort_clause[0])].flatten.reject(&:blank?)
    if order_option.size > 1
      DmsfFileRevisionCustomField.visible.pluck(:id, :name).each do |id, name|
        order_option[1].gsub!("COALESCE(cf_#{id}.value, '')", "\"#{name}\"")
      end
      order_option[1].gsub!(',', " #{$1},")
      if order_option[1] =~ /(DESC|ASC)$/
        order_option[1].gsub!(',', " #{$1},")
      end
    end
    items = base_scope.
        where(statement).
        order(order_option).
        limit(options[:limit]).
        offset(options[:offset]).to_a
    items.each do |item|
      case item.type
      when 'folder'
        dmsf_folder = DmsfFolder.find_by(id: item.id)
        if dmsf_folder && (!DmsfFolder.permissions?(dmsf_folder, false))
          items.delete item
        end
      when 'project'
        p = Project.find_by(id: item.id)
        items.delete(item) unless p&.dmsf_available?
      end
    end
    items
  end

  def extra_columns
    []
  end

  private

  def dmsf_projects_scope
    return nil if(project && !Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders'])
    cf_columns = +''
    if statement.present?
      DmsfFileRevisionCustomField.visible.order(:position).pluck(:id).each do |id|
        cf_columns << ",NULL AS cf_#{id}"
      end
    end
    scope = Project.select(%{
      projects.id AS id,
      projects.id AS project_id,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS revision_id,
      projects.name AS title,
      projects.identifier AS filename,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
      projects.updated_on AS updated,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS major_version,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS minor_version,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow_id,
      '' AS firstname,
      '' AS lastname,
      CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS author,
      'project' AS type,
      CAST(0 AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS deleted,
      0 AS sort #{cf_columns}}).visible
    if dmsf_folder_id || deleted
      scope.none
    else
      scope = scope.non_templates if scope.respond_to?(:non_templates)
      scope.where projects: { parent_id: project&.id }
    end
  end

  def dmsf_folders_scope
    cf_columns = +''
    if statement.present?
      DmsfFileRevisionCustomField.visible.order(:position).pluck(:id).each do |id|
        cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_folders.id) AS cf_#{id}"
      end
    end
    scope = DmsfFolder.select(%{
        dmsf_folders.id AS id,
        dmsf_folders.project_id AS project_id,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS revision_id,
        dmsf_folders.title AS title,
        NULL AS filename,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
        dmsf_folders.updated_at AS updated,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS major_version,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS minor_version,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow_id,
        users.firstname AS firstname,
        users.lastname AS lastname,
        users.id AS author,
        'folder' AS type,
        dmsf_folders.deleted AS deleted,
        1 AS sort #{cf_columns}}).
      joins('LEFT JOIN users ON dmsf_folders.user_id = users.id')
    return scope.none unless project
    if deleted
      scope = scope.deleted
    else
      scope = scope.visible
    end
    if dmsf_folder_id
      scope.where dmsf_folders: { dmsf_folder_id: dmsf_folder_id, deleted: deleted }
    else
      if statement.present? || deleted
        scope.where dmsf_folders: { project_id: project.id, deleted: deleted }
      else
        scope.where dmsf_folders: { project_id: project.id, dmsf_folder_id: nil, deleted: deleted }
      end
    end
  end

  def dmsf_folder_links_scope
    return nil unless project
    cf_columns = +''
    if statement.present?
      DmsfFileRevisionCustomField.visible.order(:position).pluck(:id).each do |id|
        cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_folders.id) AS cf_#{id}"
      end
    end
    scope = DmsfLink.select(%{
        dmsf_links.id AS id,
        COALESCE(dmsf_folders.project_id, dmsf_links.project_id) AS project_id,
        dmsf_links.target_id AS revision_id,
        dmsf_links.name AS title,
        dmsf_folders.title AS filename,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
        COALESCE(dmsf_folders.updated_at, dmsf_links.updated_at) AS updated,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS major_version,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS minor_version,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow_id,
        users.firstname AS firstname,
        users.lastname AS lastname,
        users.id AS author,
        'folder-link' AS type,
        dmsf_links.deleted AS deleted,
        1 AS sort #{cf_columns}}).
      joins('LEFT JOIN dmsf_folders ON dmsf_links.target_id = dmsf_folders.id').
      joins('LEFT JOIN users ON users.id = COALESCE(dmsf_folders.user_id, dmsf_links.user_id)')
    if dmsf_folder_id
      scope.where dmsf_links: { target_type: 'DmsfFolder', dmsf_folder_id: dmsf_folder_id, deleted: deleted }
    else
      if statement.present? || deleted
        scope.where dmsf_links: { target_type: 'DmsfFolder', project_id: project.id, deleted: deleted }
      else
        scope.where dmsf_links: { target_type: 'DmsfFolder', project_id: project.id, dmsf_folder_id: nil, deleted: deleted }
      end
    end
  end

  def dmsf_files_scope
    return nil unless project
    cf_columns = +''
    if statement.present?
      DmsfFileRevisionCustomField.visible.order(:position).pluck(:id).each do |id|
        cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFileRevision' AND customized_id = dmsf_file_revisions.id) AS cf_#{id}"
      end
    end
    scope = DmsfFile.select(%{
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
        2 AS sort #{cf_columns}}).
      joins(:dmsf_file_revisions).
      joins('LEFT JOIN users ON dmsf_file_revisions.user_id = users.id ').
      where(sub_query)
      if dmsf_folder_id
        scope.where dmsf_files: { dmsf_folder_id: dmsf_folder_id, deleted: deleted }
      else
        if statement.present? || deleted
          scope.where dmsf_files: { project_id: project.id, deleted: deleted }
        else
          scope.where dmsf_files: { project_id: project.id, dmsf_folder_id: nil, deleted: deleted }
        end
      end
  end

  def dmsf_file_links_scope
    return nil unless project
    cf_columns = +''
    if statement.present?
      DmsfFileRevisionCustomField.visible.order(:position).pluck(:id).each do |id|
        cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFileRevision' AND customized_id = dmsf_file_revisions.id) AS cf_#{id}"
      end
    end
    scope = DmsfLink.select(%{
        dmsf_links.id AS id,
        dmsf_files.project_id AS project_id,
        dmsf_files.id AS revision_id,
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
        2 AS sort #{cf_columns}}).
      joins('JOIN dmsf_files ON dmsf_files.id = dmsf_links.target_id').
      joins('JOIN dmsf_file_revisions ON dmsf_file_revisions.dmsf_file_id = dmsf_files.id').
      joins('LEFT JOIN users ON dmsf_file_revisions.user_id = users.id ').
      where(sub_query)
    if dmsf_folder_id
      scope.where dmsf_links: { target_type: 'DmsfFile', dmsf_folder_id: dmsf_folder_id, deleted: deleted }
    else
      if statement.present? || deleted
        scope.where dmsf_links: { target_type: 'DmsfFile', project_id: project.id, deleted: deleted }
      else
        scope.where dmsf_links: { target_type: 'DmsfFile', project_id: project.id, dmsf_folder_id: nil, deleted: deleted }
      end
    end

  end

  def dmsf_url_links_scope
    return nil unless project
    cf_columns = +''
    if statement.present?
      DmsfFileRevisionCustomField.visible.order(:position).pluck(:id).each do |id|
        cf_columns << ",NULL AS cf_#{id}"
      end
    end
    scope = DmsfLink.select(%{
        dmsf_links.id AS id,
        dmsf_links.project_id AS project_id,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS revision_id,
        dmsf_links.name AS title,
        dmsf_links.external_url AS filename,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS size,
        dmsf_links.updated_at AS updated,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS major_version,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS minor_version,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow,
        CAST(NULL AS #{ActiveRecord::Base.connection.type_to_sql(:decimal)}) AS workflow_id,
        users.firstname AS firstname,
        users.lastname AS lastname,
        users.id AS author,
        'url-link' AS type,
        dmsf_links.deleted AS deleted,
         2 AS sort #{cf_columns}}).
      joins('LEFT JOIN users ON dmsf_links.user_id = users.id ')
    if dmsf_folder_id
      scope.where dmsf_links: { target_type: 'DmsfUrl', dmsf_folder_id: dmsf_folder_id, deleted: deleted }
    else
      if statement.present? || deleted
        scope.where dmsf_links: { target_type: 'DmsfUrl', project_id: project.id, deleted: deleted }
      else
        scope.where dmsf_links: { target_type: 'DmsfUrl', project_id: project.id, dmsf_folder_id: nil, deleted: deleted }
      end
    end
  end

  def sub_query
    case ActiveRecord::Base.connection.adapter_name.downcase
    when 'sqlserver'
      'dmsf_file_revisions.id = (SELECT TOP 1 r.id FROM dmsf_file_revisions r WHERE r.created_at = (SELECT MAX(created_at) FROM dmsf_file_revisions rr WHERE rr.dmsf_file_id = dmsf_files.id) AND r.dmsf_file_id = dmsf_files.id ORDER BY id DESC)'
    else
      'dmsf_file_revisions.id = (SELECT r.id FROM dmsf_file_revisions r WHERE r.created_at = (SELECT MAX(created_at) FROM dmsf_file_revisions rr WHERE rr.dmsf_file_id = dmsf_files.id) AND r.dmsf_file_id = dmsf_files.id ORDER BY id DESC LIMIT 1)'
   end
  end

end
