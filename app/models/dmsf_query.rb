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

  attr_accessor :dmsf_folder, :project

  # Standard columns
  self.available_columns = [
      QueryColumn.new(:id, sortable: 'id', caption: '#'),
      DmsfTitleQueryColumn.new(:title, frozen: true),
      QueryColumn.new(:extension),
      QueryColumn.new(:size),
      DmsfModifiedQueryColumn.new(:modified),
      DmsfVersionQueryColumn.new(:version),
      QueryColumn.new(:workflow),
      DmsfAuthorQueryColumn.new(:author),
  ]

  def initialize(attributes)
    super attributes
    self.sort_criteria = []
    self.filters = {}
    @deleted = false
    @dmsf_folder_id = @dmsf_folder ? @dmsf_folder.id : nil
  end

  ######################################################################################################################
  # Inherited
  #

  def available_columns
    unless @available_columns
      @available_columns = self.class.available_columns.dup
      @available_columns += DmsfFileRevisionCustomField.visible.collect { |cf| QueryCustomFieldColumn.new(cf) }
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
    [['title', 'desc']]
  end

  def base_scope
    unless @scope
      @scope = [dmsf_folders_scope, dmsf_folder_links_scope, dmsf_files_scope, dmsf_file_links_scope, dmsf_url_links_scope].inject(:union_all)
    end
    @scope
  end

  # Returns the issue count
  def dmsf_count
    base_scope.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def type
    'DmsfQuery'
  end

  ######################################################################################################################
  # New

  def dmsf_nodes(options={})
    nodes = base_scope.
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
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_folders.id) AS `#{name}`"
    end
    DmsfFolder.
        select(%{
          dmsf_folders.id AS id,
          dmsf_folders.title AS title,
          NULL AS filename,
          NULL AS extensions,
          NULL AS size,
          dmsf_folders.updated_at AS updated,
          NULL AS major_version,
          NULL AS minor_version,
          NULL AS workflow,
          users.firstname AS firstname,
	        users.lastname AS lastname,
          'DmsfFolder' AS type,
          0 AS sort #{cf_columns}}).
        joins('LEFT JOIN users ON dmsf_folders.user_id = users.id').
        where(dmsf_folders: { project_id: @project.id, dmsf_folder_id: @dmsf_folder_id, deleted: @deleted })
  end

  def dmsf_folder_links_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_folders.id) AS `#{name}`"
    end
    DmsfLink.
        select(%{
          dmsf_folders.id AS id,
          dmsf_folders.title AS title,
          NULL AS filename,
          NULL AS extensions,
          NULL AS size,
          dmsf_folders.updated_at AS updated,
          NULL AS major_version,
          NULL AS minor_version,
          NULL AS workflow,
          users.firstname AS firstname,
	        users.lastname AS lastname,
          'DmsfFolderLink' AS type,
          0 AS sort #{cf_columns}}).
        joins('JOIN dmsf_folders ON dmsf_links.target_id = dmsf_folders.id').
        joins('LEFT JOIN users ON dmsf_folders.user_id = users.id ').
        where(dmsf_links: { target_type: 'DmsfFolder', project_id: @project.id, dmsf_folder_id: @dmsf_folder_id,
                            deleted: @deleted })
  end

  def dmsf_files_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_files.id) AS `#{name}`"
    end
    DmsfFile.
        select(%{
          dmsf_files.id AS id,
          dmsf_file_revisions.name AS title,
          dmsf_file_revisions.disk_filename AS filename,
          SUBSTR(dmsf_file_revisions.disk_filename, POSITION('.' IN dmsf_file_revisions.disk_filename) + 1, LENGTH(dmsf_file_revisions.disk_filename) - POSITION('.' IN dmsf_file_revisions.disk_filename)) AS extensions,
          dmsf_file_revisions.size AS size,
          dmsf_file_revisions.updated_at AS updated,
          dmsf_file_revisions.major_version AS major_version,
	        dmsf_file_revisions.minor_version AS minor_version,
          dmsf_file_revisions.workflow AS workflow,
          users.firstname AS firstname,
	        users.lastname AS lastname,
          'DmsfFile' AS type,
          1 AS sort #{cf_columns}}).
        joins(:dmsf_file_revisions).
        joins('LEFT JOIN users ON dmsf_file_revisions.user_id = users.id ').
        where('dmsf_file_revisions.created_at = (SELECT MAX(r.created_at) FROM dmsf_file_revisions r WHERE r.dmsf_file_id = dmsf_file_revisions.dmsf_file_id)').
        where(dmsf_files: { project_id: @project.id, dmsf_folder_id: @dmsf_folder_id, deleted: @deleted })
  end

  def dmsf_file_links_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:id, :name).each do |id, name|
      cf_columns << ",(SELECT value from custom_values WHERE custom_field_id = #{id} AND customized_type = 'DmsfFolder' AND customized_id = dmsf_files.id) AS `#{name}`"
    end
    DmsfLink.
        select(%{
          dmsf_files.id AS id,
          dmsf_links.name AS title,
          dmsf_file_revisions.disk_filename AS filename,
          SUBSTR(dmsf_file_revisions.disk_filename, POSITION('.' IN dmsf_file_revisions.disk_filename) + 1, LENGTH(dmsf_file_revisions.disk_filename) - POSITION('.' IN dmsf_file_revisions.disk_filename)) AS extensions,
          dmsf_file_revisions.size AS size,
          dmsf_file_revisions.updated_at AS updated,
          dmsf_file_revisions.major_version AS major_version,
	        dmsf_file_revisions.minor_version AS minor_version,
          dmsf_file_revisions.workflow AS workflow,
          users.firstname AS firstname,
	        users.lastname AS lastname,
          'DmsfFileLink' AS type,
          1 AS sort #{cf_columns}}).
        joins('JOIN dmsf_files ON dmsf_files.id = dmsf_links.target_id').
        joins('JOIN dmsf_file_revisions ON dmsf_file_revisions.dmsf_file_id = dmsf_files.id').
        joins('LEFT JOIN users ON dmsf_file_revisions.user_id = users.id ').
        where('dmsf_file_revisions.created_at = (SELECT MAX(r.created_at) FROM dmsf_file_revisions r WHERE r.dmsf_file_id = dmsf_file_revisions.dmsf_file_id)').
        where(dmsf_files: { project_id: @project.id, dmsf_folder_id: @dmsf_folder_id, deleted: @deleted })
  end

  def dmsf_url_links_scope
    cf_columns = +''
    DmsfFileRevisionCustomField.visible.order(:position).pluck(:name).each do |name|
      cf_columns << ",NULL AS `#{name}`"
    end
    DmsfLink.
        select(%{
          dmsf_links.id AS id,
          dmsf_links.name AS title,
          dmsf_links.external_url AS filename,
          NULL AS extensions,
          NULL AS size,
          dmsf_links.updated_at AS updated,
	        NULL AS major_version,
          NULL AS minor_version,
          NULL AS workflow,
          users.firstname AS firstname,
	        users.lastname AS lastname,
          'DmsfUrlLink' AS type,
          1 AS sort #{cf_columns}}).
        joins('LEFT JOIN users ON dmsf_links.user_id = users.id ').
        where(target_type: 'DmsfUrl', project_id: @project.id,  dmsf_folder_id: @dmsf_folder_id, deleted: @deleted)
  end

end
