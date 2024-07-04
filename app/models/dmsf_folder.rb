# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
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

require "#{File.dirname(__FILE__)}/../../lib/redmine_dmsf/lockable"

# Folder
class DmsfFolder < ApplicationRecord
  include RedmineDmsf::Lockable

  belongs_to :project
  belongs_to :dmsf_folder
  belongs_to :deleted_by_user, class_name: 'User'
  belongs_to :user

  has_many :dmsf_folders, -> { order :title }, dependent: :destroy, inverse_of: :dmsf_folder
  has_many :dmsf_files, dependent: :destroy
  has_many :folder_links, -> { where(target_type: 'DmsfFolder').order(:name) },
           class_name: 'DmsfLink', foreign_key: 'dmsf_folder_id', dependent: :destroy, inverse_of: :dmsf_folder
  has_many :file_links, -> { where(target_type: 'DmsfFile') },
           class_name: 'DmsfLink', foreign_key: 'dmsf_folder_id', dependent: :destroy, inverse_of: :dmsf_folder
  has_many :url_links, -> { where(target_type: 'DmsfUrl') },
           class_name: 'DmsfLink', foreign_key: 'dmsf_folder_id', dependent: :destroy, inverse_of: :dmsf_folder
  has_many :dmsf_links, dependent: :destroy
  has_many :referenced_links, -> { where(target_type: 'DmsfFolder') },
           class_name: 'DmsfLink', foreign_key: 'target_id', dependent: :destroy, inverse_of: :dmsf_folder
  has_many :locks, -> { where(entity_type: 1).order(updated_at: :desc) },
           class_name: 'DmsfLock', foreign_key: 'entity_id', dependent: :destroy, inverse_of: :dmsf_folder
  has_many :dmsf_folder_permissions, dependent: :destroy

  INVALID_CHARACTERS = '\[\]\/\\\?":<>#%\*'
  STATUS_DELETED = 1
  STATUS_ACTIVE = 0
  AVAILABLE_COLUMNS = %w[id title size modified version workflow author description comment].freeze
  DEFAULT_COLUMNS = %w[title size modified version workflow author].freeze

  def self.visible_condition(system: true)
    Project.allowed_to_condition(User.current, :view_dmsf_folders) do |role, user|
      if role.member?
        group_ids = user.group_ids.join(',')
        group_ids = -1 if group_ids.blank?
        allowed = system && role.allowed_to?(:display_system_folders) ? 1 : 0
        %{
          ((dfp.object_id IS NULL) OR
          (dfp.object_id = #{role.id} AND dfp.object_type = 'Role') OR
          ((dfp.object_id = #{user.id} OR dfp.object_id IN (#{group_ids})) AND dfp.object_type = 'User')) AND
          (#{DmsfFolder.table_name}.system = #{DmsfFolder.connection.quoted_false} OR 1 = #{allowed})
        }
      end
    end
  end

  scope :visible, (lambda do |*args|
    system = args.shift || true
    joins(:project)
      .joins("LEFT JOIN #{DmsfFolderPermission.table_name} dfp ON #{DmsfFolder.table_name}.id = dfp.dmsf_folder_id")
      .where(deleted: STATUS_ACTIVE).where(DmsfFolder.visible_condition(system: system)).distinct
  end)
  scope :deleted, lambda {
    joins(:project)
      .joins("LEFT JOIN #{DmsfFolderPermission.table_name} dfp ON #{DmsfFolder.table_name}.id = dfp.dmsf_folder_id")
      .where(deleted: STATUS_DELETED).where(DmsfFolder.visible_condition).distinct
  }
  scope :issystem, -> { where(system: true, deleted: STATUS_ACTIVE) }

  acts_as_customizable
  acts_as_searchable columns: ["#{table_name}.title", "#{table_name}.description"],
                     project_key: 'project_id',
                     date_column: 'updated_at',
                     permission: :view_dmsf_files,
                     scope: proc { DmsfFolder.visible }
  acts_as_watchable
  acts_as_event title: proc { |o| o.title },
                description: proc { |o| o.description },
                url: proc { |o| { controller: 'dmsf', action: 'show', id: o.project, folder_id: o } },
                datetime: proc { |o| o.updated_at },
                author: proc { |o| o.user }

  validates :title, presence: true, dmsf_file_name: true
  validates :title, uniqueness: { scope: %i[dmsf_folder_id project_id deleted],
                                  conditions: -> { where(deleted: STATUS_ACTIVE) }, case_sensitive: true }
  validates :description, length: { maximum: 65_535 }
  validates :dmsf_folder, dmsf_folder_parent: true, if: proc { |folder| !folder.new_record? }

  before_create :default_values

  def visible?(_user = User.current)
    return DmsfFolder.visible.exists?(id: id) if respond_to?(:type) && /^folder/.match?(type)

    true
  end

  def self.permissions?(folder, allow_system: true, file: false)
    # Administrator?
    return true if User.current&.admin? || folder.nil?

    # Permissions to the project?
    # If file is true we work just with the file and not viewing the folder
    return false unless file || User.current&.allowed_to?(:view_dmsf_folders, folder.project)

    # System folder?
    if folder&.system
      return false unless allow_system || User.current.allowed_to?(:display_system_folders, folder.project)
      return false if folder.title != '.Issues' && !folder.issue&.visible?(User.current)
    end
    # Permissions to the folder?
    if folder.dmsf_folder_permissions.any?
      role_ids = User.current.roles_for_project(folder.project).map(&:id)
      role_permission_ids = folder.dmsf_folder_permissions.roles.map(&:object_id)
      if RUBY_VERSION < '3.1' # intersect? method added in Ruby 3.1, though we support 2.7 too
        return true if role_ids.intersection(role_permission_ids).any?
      elsif role_ids.intersect?(role_permission_ids)
        return true
      end

      principal_ids = folder.dmsf_folder_permissions.users.map(&:object_id)
      return true if principal_ids.include?(User.current.id)

      user_group_ids = User.current.groups.map(&:id)
      if RUBY_VERSION < '3.1' # intersect? method added in Ruby 3.1, though we support 2.7 too
        principal_ids.intersection(user_group_ids).any?
      else
        principal_ids.intersect?(user_group_ids)
      end
    else
      DmsfFolder.permissions? folder.dmsf_folder, allow_system: allow_system, file: file
    end
  end

  def initialize(*args)
    super
    self.watcher_user_ids = [] if new_record?
  end

  def default_values
    self.notification = true if Setting.plugin_redmine_dmsf['dmsf_default_notifications'].present? && !system
  end

  def locked_by
    if lock && lock.reverse[0]
      user = lock.reverse[0].user
      return user == User.current ? l(:label_me) : user.name if user
    end
    ''
  end

  def delete(commit: false)
    if locked?
      errors.add :base, l(:error_folder_is_locked)
      return false
    end
    if commit
      destroy
    else
      delete_recursively
    end
  end

  def delete_recursively
    self.deleted = STATUS_DELETED
    self.deleted_by_user = User.current
    save!
    dmsf_files.each(&:delete)
    dmsf_links.each(&:delete)
    dmsf_folders.each(&:delete_recursively)
  end

  def deleted?
    deleted == STATUS_DELETED
  end

  def restore
    if dmsf_folder&.deleted?
      errors.add :base, l(:error_parent_folder)
      return false
    end
    restore_recursively
  end

  def restore_recursively
    self.deleted = STATUS_ACTIVE
    self.deleted_by_user = nil
    save!
    dmsf_files.each(&:restore)
    dmsf_links.each(&:restore)
    dmsf_folders.each(&:restore_recursively)
  end

  def dmsf_path
    folder = self
    path = []
    while folder
      path.unshift folder
      folder = folder.dmsf_folder
    end
    path
  end

  def dmsf_path_str
    path = dmsf_path
    string_path = path.map(&:title)
    string_path.join '/'
  end

  def notify?
    notification || dmsf_folder&.notify? || (!dmsf_folder && project.dmsf_notification)
  end

  def get_all_watchers(watchers)
    watchers << notified_watchers
    watchers << if dmsf_folder
                  dmsf_folder.notified_watchers
                else
                  project.notified_watchers
                end
  end

  def notify_deactivate
    self.notification = nil
    save!
  end

  def notify_activate
    self.notification = true
    save!
  end

  def self.directory_tree(project)
    tree = [[l(:link_documents), nil]]
    project = Project.find(project) unless project.is_a?(Project)
    folders = project.dmsf_folders.visible.to_a
    folders.delete_if(&:locked_for_user?)
    folders.each do |folder|
      tree.push ["...#{folder.title}", folder.id]
      DmsfFolder.directory_subtree tree, folder, 2
    end
    tree
  end

  def folder_tree
    tree = [[title, id]]
    DmsfFolder.directory_subtree tree, self, 1
    tree
  end

  def self.file_list(files)
    options = []
    options.push ['', nil, { label: 'none' }]
    files.each do |f|
      options.push [f.title, f.id]
    end
    options
  end

  # Returns an array of projects that current user can copy folder to
  def self.allowed_target_projects_on_copy
    projects = []
    if User.current.admin?
      projects = Project.visible.has_module('dmsf').all
    elsif User.current.logged?
      User.current.memberships.each do |m|
        if m.project.module_enabled?('dmsf') &&
           m.roles.detect { |r| r.allowed_to?(:folder_manipulation) && r.allowed_to?(:file_manipulation) }
          projects << m.project
        end
      end
    end
    projects
  end

  def move_to(target_project, target_folder)
    if project != target_project
      dmsf_files.visible.find_each do |f|
        f.move_to target_project, f.dmsf_folder
      end
      dmsf_folders.visible.find_each do |s|
        s.move_to target_project, s.dmsf_folder
      end
      dmsf_links.visible.find_each do |l|
        l.move_to target_project, l.dmsf_folder
      end
      self.project = target_project
    end
    self.dmsf_folder = target_folder
    save
  end

  def copy_to(project, folder, copy_files: true)
    new_folder = DmsfFolder.new
    new_folder.dmsf_folder = folder
    new_folder.project = folder ? folder.project : project
    new_folder.title = title
    new_folder.description = description
    new_folder.user = User.current
    new_folder.custom_values = []
    new_folder.custom_field_values =
      custom_field_values.each_with_object({}) do |v, h|
        h[v.custom_field_id] = v.value
      end
    unless new_folder.save
      Rails.logger.error new_folder.errors.full_messages.to_sentence
      return new_folder
    end
    if copy_files
      dmsf_files.visible.find_each do |f|
        f.copy_to project, new_folder
      end
      dmsf_links.visible.find_each do |l|
        l.copy_to project, new_folder
      end
    end
    dmsf_folders.visible.find_each do |s|
      s.copy_to project, new_folder, copy_files: copy_files
    end
    dmsf_folder_permissions.find_each do |p|
      p.copy_to new_folder
    end
    new_folder
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    DmsfFileRevisionCustomField.all
  end

  def custom_values
    # We need to response with DmsfFileRevision custom values if DmsfFolder just covers files in the union of the main
    # view
    if respond_to?(:type) && /^file/.match?(type)
      return CustomValue.where(customized_type: 'DmsfFileRevision', customized_id: revision_id)
    end

    super
  end

  def modified
    last_update = updated_at
    time = DmsfFolder.where(['project_id = ? AND dmsf_folder_id = ? AND updated_at > ?', project_id, id, last_update])
                     .maximum(:updated_at)
    last_update = time if time
    time = DmsfFile.where(['project_id = ? AND dmsf_folder_id = ? AND updated_at > ?', project_id, id, last_update])
                   .maximum(:updated_at)
    last_update = time if time
    time = DmsfLink.where(['project_id = ? AND dmsf_folder_id = ? AND updated_at > ?', project_id, id, last_update])
                   .maximum(:updated_at)
    last_update = time if time
    last_update
  end

  # Number of items in the folder
  def items
    dmsf_folders.visible.where(project_id: project_id).all.size +
      dmsf_files.visible.where(project_id: project_id).all.size +
      dmsf_links.visible.where(project_id: project_id).all.size
  end

  def self.column_on?(column)
    dmsf_columns = Setting.plugin_redmine_dmsf['dmsf_columns']
    dmsf_columns ||= DmsfFolder::DEFAULT_COLUMNS
    dmsf_columns.include? column
  end

  def custom_value(custom_field)
    custom_field_values.each do |cv|
      return cv if cv.custom_field == custom_field
    end

    nil
  end

  def self.get_column_position(column)
    dmsf_columns = Setting.plugin_redmine_dmsf['dmsf_columns']
    dmsf_columns ||= DmsfFolder::DEFAULT_COLUMNS
    pos = 0
    # 0 - checkbox
    # 1 - id
    if dmsf_columns.include?('id')
      pos += 1
      return pos if column == 'id'
    elsif column == 'id'
      return nil
    end

    # 2 - title
    if dmsf_columns.include?('title')
      pos += 1
      return pos if column == 'title'
    elsif column == 'title'
      return nil
    end

    # 3 - size
    if dmsf_columns.include?('size')
      pos += 1
      return pos if column == 'size'
    elsif column == 'size'
      return nil
    end

    # 4 - modified
    if dmsf_columns.include?('modified')
      pos += 1
      return pos if column == 'modified'
    elsif column == 'modified'
      return nil
    end

    # 5 - version
    if dmsf_columns.include?('version')
      pos += 1
      return pos if column == 'version'
    elsif column == 'version'
      return nil
    end

    # 6 - workflow
    if dmsf_columns.include?('workflow')
      pos += 1
      return pos if column == 'workflow'
    elsif column == 'workflow'
      return nil
    end

    # 7 - author
    if dmsf_columns.include?('author')
      pos += 1
      return pos if column == 'author'
    elsif column == 'author'
      return nil
    end

    # 9 - custom fields
    DmsfFileRevisionCustomField.visible.each do |c|
      pos += 1 if DmsfFolder.column_on?(c.name)
    end
    # 8 - commands
    pos += 1
    return pos if column == 'commands'

    # 9 - (position)
    pos += 1
    return pos if column == 'position'

    # 10 - (size calculated)
    pos += 1
    return pos if column == 'size_calculated'

    # 11 - (modified calculated)
    pos += 1
    return pos if column == 'modified_calculated'

    # 12 - (version calculated)
    pos += 1
    return pos if column == 'version_calculated'

    # 13 - (clear title)
    pos += 1
    return pos if column == 'clear_title'

    nil
  end

  def issue
    if @issue.nil? && system
      issue_id = title.to_i
      @issue = Issue.find_by(id: issue_id) if issue_id.positive?
    end
    @issue
  end

  def update_from_params(params)
    # Attributes
    self.title = params[:dmsf_folder][:title].scrub.strip
    self.description = params[:dmsf_folder][:description].scrub.strip
    self.dmsf_folder_id = params[:parent_id].presence || params[:dmsf_folder][:dmsf_folder_id]
    self.system = params[:dmsf_folder][:system].present?
    # Custom fields
    if params[:dmsf_folder][:custom_field_values].present?
      i = 0
      params[:dmsf_folder][:custom_field_values].each do |param|
        custom_field_values[i].value = param[1]
        i += 1
      end
    end
    # Permissions
    dmsf_folder_permissions.delete_all
    if params[:permissions]
      params[:permissions][:role_ids]&.each do |role_id|
        permission = DmsfFolderPermission.new
        permission.object_id = role_id
        permission.object_type = Role.model_name.to_s
        dmsf_folder_permissions << permission
      end
      params[:permissions][:user_ids]&.each do |user_id|
        permission = DmsfFolderPermission.new
        permission.object_id = user_id
        permission.object_type = User.model_name.to_s
        dmsf_folder_permissions << permission
      end
    end
    # Save
    save
  end

  ALL_INVALID_CHARACTERS = /[#{INVALID_CHARACTERS}]/
  def self.get_valid_title(title)
    # 1. Invalid characters are replaced with dots.
    # 2. Two or more dots in a row are replaced with a single dot.
    # 3. Windows' WebClient does not like a dot at the end.
    title.scrub.gsub(ALL_INVALID_CHARACTERS, '.').gsub(/\.{2,}/, '.').chomp('.')
  end

  def permission_for_role(role)
    dmsf_folder_permissions.roles.exists? object_id: role.id
  end

  def permissions_users
    Principal.active.where id: dmsf_folder_permissions.users.map(&:object_id)
  end

  def inherited_permissions_from
    return nil unless dmsf_folder

    if dmsf_folder.dmsf_folder_permissions.any?
      dmsf_folder
    else
      dmsf_folder.inherited_permissions_from
    end
  end

  def self.visible_folders(folders, project)
    allowed = Setting.plugin_redmine_dmsf['dmsf_act_as_attachable'] &&
              (project.dmsf_act_as_attachable == Project::ATTACHABLE_DMS_AND_ATTACHMENTS) &&
              User.current.allowed_to?(:display_system_folders, project)
    folders.reject do |folder|
      if folder.system
        if allowed
          issue_id = folder.title.to_i
          if issue_id.positive?
            issue = Issue.find_by(id: issue_id)
            !issue&.visible? User.current
          else
            false
          end
        else
          true
        end
      else
        false
      end
    end
  end

  def css_classes(trash)
    classes = []
    if trash
      if title.match?(/^\./)
        classes << 'dmsf-system'
      else
        classes << 'hascontextmenu'
        classes << 'dmsf-gray' if type.match?(/link$/)
      end
    else
      classes << 'dmsf-tree'
      if %w[folder project].include?(type)
        classes << 'dmsf-collapsed'
        classes << 'dmsf-not-loaded'
      else
        classes << 'dmsf-child'
      end
      if title.match?(/^\./)
        classes << 'dmsf-system'
      else
        classes << 'hascontextmenu'
        classes << 'dmsf-draggable' if type != 'project'
        classes << 'dmsf-droppable' if %w[project folder].include? type
        classes << 'dmsf-gray' if type.match?(/link$/)
      end
    end
    classes.join ' '
  end

  def empty?
    !(dmsf_folders.visible.exists? || dmsf_files.visible.exists? || dmsf_links.visible.exists?)
  end

  def to_s
    title
  end

  # Check whether any child folder is equal to the folder
  def any_child?(folder)
    dmsf_folders.each do |child|
      return true if child == folder

      child.any_child? folder
    end
    false
  end

  class << self
    def directory_subtree(tree, folder, level)
      folders = folder.dmsf_folders.visible.to_a
      folders.delete_if(&:locked_for_user?)
      folders.each do |subfolder|
        tree.push ["#{'...' * level}#{subfolder.title}", subfolder.id]
        DmsfFolder.directory_subtree tree, subfolder, level + 1
      end
    end
  end
end
