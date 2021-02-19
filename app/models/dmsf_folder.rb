# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-21 Karel Pičman <karel.picman@konton.com>
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

class DmsfFolder < ActiveRecord::Base

  include RedmineDmsf::Lockable

  belongs_to :project
  belongs_to :dmsf_folder
  belongs_to :deleted_by_user, class_name: 'User', foreign_key: 'deleted_by_user_id'
  belongs_to :user

  has_many :dmsf_folders, -> { order :title }, dependent: :destroy
  has_many :dmsf_files, dependent: :destroy
  has_many :folder_links, -> { where(target_type: 'DmsfFolder').order(:name) },
    class_name: 'DmsfLink', foreign_key: 'dmsf_folder_id', dependent: :destroy
  has_many :file_links, -> { where(target_type: 'DmsfFile') },
    class_name: 'DmsfLink', foreign_key: 'dmsf_folder_id', dependent: :destroy
  has_many :url_links, -> { where(target_type: 'DmsfUrl') },
    class_name: 'DmsfLink', foreign_key: 'dmsf_folder_id', dependent: :destroy
  has_many :dmsf_links, dependent: :destroy
  has_many :referenced_links, -> { where(target_type: 'DmsfFolder') },
    class_name: 'DmsfLink', foreign_key: 'target_id', dependent: :destroy
  has_many :locks, -> { where(entity_type:  1).order(updated_at: :desc) },
    class_name: 'DmsfLock', foreign_key: 'entity_id', dependent: :destroy
  has_many :dmsf_folder_permissions, dependent: :destroy

  INVALID_CHARACTERS = '\[\]\/\\\?":<>#%\*'
  STATUS_DELETED = 1
  STATUS_ACTIVE = 0
  AVAILABLE_COLUMNS = %w(id title size modified version workflow author).freeze
  DEFAULT_COLUMNS = %w(title size modified version workflow author).freeze

  def self.visible_condition(system=true)
    Project.allowed_to_condition(User.current, :view_dmsf_folders) do |role, user|
      if role.member?
        group_ids = user.group_ids.join(',')
        group_ids = -1 if group_ids.blank?
        allowed = (system && role.allowed_to?(:display_system_folders)) ? 1 : 0
        %{
          ((#{DmsfFolderPermission.table_name}.object_id IS NULL) OR
          (#{DmsfFolderPermission.table_name}.object_id = #{role.id} AND #{DmsfFolderPermission.table_name}.object_type = 'Role') OR
          ((#{DmsfFolderPermission.table_name}.object_id = #{user.id} OR #{DmsfFolderPermission.table_name}.object_id IN (#{group_ids})) AND #{DmsfFolderPermission.table_name}.object_type = 'User')) AND
          (#{DmsfFolder.table_name}.system = #{DmsfFolder.connection.quoted_false} OR 1 = #{allowed})
        }
      end
    end
  end

  scope :visible, -> (system=true) { joins(:project).joins(
    "LEFT JOIN #{DmsfFolderPermission.table_name} ON #{DmsfFolder.table_name}.id = #{DmsfFolderPermission.table_name}.dmsf_folder_id").where(
    deleted: STATUS_ACTIVE).where(DmsfFolder.visible_condition(system)).distinct
  }
  scope :deleted, -> { joins(:project).joins(
    "LEFT JOIN #{DmsfFolderPermission.table_name} ON #{DmsfFolder.table_name}.id = #{DmsfFolderPermission.table_name}.dmsf_folder_id").where(
    deleted: STATUS_DELETED).where(DmsfFolder.visible_condition).distinct
  }
  scope :issystem, -> { where(system: true) }
  scope :notsystem, -> { where(system: false) }

  acts_as_customizable

  acts_as_searchable columns: ["#{table_name}.title", "#{table_name}.description"],
        project_key: 'project_id',
        date_column: 'updated_at',
        permission: :view_dmsf_files,
        scope: Proc.new { DmsfFolder.visible }

  acts_as_event title: Proc.new { |o| o.title },
          description: Proc.new { |o| o.description },
          url: Proc.new { |o| { controller: 'dmsf', action: 'show', id: o.project, folder_id: o } },
          datetime: Proc.new { |o| o.updated_at },
          author: Proc.new { |o| o.user }

  validates :title, presence: true, dmsf_file_name: true
  validates :project, presence: true
  validates_uniqueness_of :title, scope: [:dmsf_folder_id, :project_id, :deleted],
    conditions: -> { where(deleted: STATUS_ACTIVE) }
  validates :description, length: { maximum: 65535 }
  validates :dmsf_folder, dmsf_folder_parent: true, if: Proc.new { |folder| !folder.new_record? }

  before_create :default_values

  def self.permissions?(folder, allow_system = true)
    # Administrator?
    return true if (User.current.admin? || folder.nil?)
    # System folder?
    if folder && folder.system
      return false unless allow_system || User.current.allowed_to?(:display_system_folders, folder.project)
      return false if folder.issue && !folder.issue.visible?(User.current)
    end
    # Permissions?
    if folder.dmsf_folder_permissions.any?
      role_ids = User.current.roles_for_project(folder.project).map{ |r| r.id }
      role_permission_ids = folder.dmsf_folder_permissions.roles.map{ |p| p.object_id }
      return true if (role_ids & role_permission_ids).any?
      principal_ids = folder.dmsf_folder_permissions.users.map{ |p| p.object_id }
      return true if principal_ids.include?(User.current.id)
      user_group_ids = User.current.groups.map{ |g| g.id }
      return true if (principal_ids & user_group_ids).any?
      return false
    end
    DmsfFolder.permissions?(folder.dmsf_folder, allow_system)
  end

  def default_values
    if Setting.plugin_redmine_dmsf['dmsf_default_notifications'] == '1' && !system
      self.notification = true
    end
  end

  def locked_by
    if lock && lock.reverse[0]
      user = lock.reverse[0].user
      if user
        return (user == User.current) ? l(:label_me) : user.name
      end
    end
    ''
  end

  def delete(commit = false)
    if locked?
      errors[:base] << l(:error_folder_is_locked)
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
    self.dmsf_files.each(&:delete)
    self.dmsf_links.each(&:delete)
    self.dmsf_folders.each(&:delete_recursively)
  end

  def deleted?
    deleted == STATUS_DELETED
  end

  def restore
    if dmsf_folder&.deleted?
      errors[:base] << l(:error_parent_folder)
      return false
    end
    restore_recursively
  end

  def restore_recursively
    self.deleted = STATUS_ACTIVE
    self.deleted_by_user = nil
    save!
    self.dmsf_files.each(&:restore)
    self.dmsf_links.each(&:restore)
    self.dmsf_folders.each(&:restore_recursively)
  end

  def dmsf_path
    folder = self
    path = []
    while folder
      path.unshift(folder)
      folder = folder.dmsf_folder
    end
    path
  end

  def dmsf_path_str
    path = dmsf_path
    string_path = path.map { |element| element.title }
    File.join string_path
  end

  def notify?
    return true if notification
    return true if dmsf_folder&.notify?
    return true if !dmsf_folder && project.dmsf_notification
    false
  end

  def notify_deactivate
    self.notification = nil
    save!
  end

  def notify_activate
    self.notification = true
    save!
  end

  def self.directory_tree(project, current_folder = nil)
    tree = [[l(:link_documents), nil]]
    project = Project.find(project) unless project.is_a?(Project)
    folders = project.dmsf_folders.visible.to_a
    # TODO: This prevents copying folders into its sub-folders too. It should be allowed.
    folders.delete(current_folder)
    folders = folders.delete_if{ |f| f.locked_for_user? }
    folders.each do |folder|
      tree.push ["...#{folder.title}", folder.id]
      DmsfFolder.directory_subtree tree, folder, 2, current_folder
    end
    return tree
  end

  def folder_tree
    tree = [[title, id]]
    DmsfFolder.directory_subtree tree, self, 1, nil
    tree
  end

  def self.file_list(files)
    options = Array.new
    options.push ['', nil, label: 'none']
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
        projects << m.project if m.project.module_enabled?('dmsf') &&
          m.roles.detect { |r| r.allowed_to?(:folder_manipulation) && r.allowed_to?(:file_manipulation) }
      end
    end
    projects
  end

  def move_to(target_project, target_folder)
    if self.project != target_project
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

  def copy_to(project, folder)
    new_folder = DmsfFolder.new
    new_folder.dmsf_folder = folder ? folder : nil
    new_folder.project = folder ? folder.project : project
    new_folder.title = title
    new_folder.description = description
    new_folder.user = User.current
    new_folder.custom_values = []
    custom_values.each do |cv|
      v = CustomValue.new
      v.custom_field = cv.custom_field
      v.value = cv.value
      new_folder.custom_values << v
    end
    unless new_folder.save
      Rails.logger.error new_folder.errors.full_messages.to_sentence
      return new_folder
    end
    dmsf_files.visible.find_each do |f|
      f.copy_to project, new_folder
    end
    dmsf_folders.visible.find_each do |s|
      s.copy_to project, new_folder
    end
    dmsf_links.visible.find_each do |l|
      l.copy_to project, new_folder
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
    if self.respond_to?(:type)
      if /^file/.match?(type)
        return CustomValue.where(customized_type: 'DmsfFileRevision', customized_id: revision_id)
      end
    end
    super
  end

  def modified
    last_update = updated_at
    time = DmsfFolder.where(
      ['project_id = ? AND dmsf_folder_id = ? AND updated_at > ?',
       project_id, id, last_update]).maximum(:updated_at)
    last_update = time if time
    time = DmsfFile.where(
      ['project_id = ? AND dmsf_folder_id = ? AND updated_at > ?',
       project_id, id, last_update]).maximum(:updated_at)
    last_update = time if time
    time = DmsfLink.where(
      ['project_id = ? AND dmsf_folder_id = ? AND updated_at > ?',
       project_id, id, last_update]).maximum(:updated_at)
    last_update = time if time
    last_update
  end


  # Number of items in the folder
  def items
    dmsf_folders.visible.where(project_id: project_id).all.size +
    dmsf_files.visible.where(project_id: project_id).all.size +
    dmsf_links.visible.where(project_id: project_id).all.size
  end
  
  def self.is_column_on?(column)
    dmsf_columns = Setting.plugin_redmine_dmsf['dmsf_columns']
    dmsf_columns = DmsfFolder::DEFAULT_COLUMNS unless dmsf_columns
    dmsf_columns.include? column
  end

  def custom_value(custom_field)
    custom_field_values.each do |cv|
      if cv.custom_field == custom_field
        return cv
      end
    end
    nil
  end

  def self.get_column_position(column)
    dmsf_columns = Setting.plugin_redmine_dmsf['dmsf_columns']
    dmsf_columns = DmsfFolder::DEFAULT_COLUMNS unless dmsf_columns
    pos = 0
    # 0 - checkbox
    # 1 - id
    if dmsf_columns.include?('id')
      pos += 1
      return pos if column == 'id'
    else
      return nil if column == 'id'
    end
    # 2 - title
    if dmsf_columns.include?('title')
      pos += 1
      return pos if column == 'title'
    else
      return nil if column == 'title'
    end
    # 3 - size
    if dmsf_columns.include?('size')
      pos += 1
      return pos if column == 'size'
    else
      return nil if column == 'size'
    end
    # 4 - modified
    if dmsf_columns.include?('modified')
      pos += 1
      return pos if column == 'modified'
    else
      return nil if column == 'modified'
    end
    # 5 - version
    if dmsf_columns.include?('version')
      pos += 1
      return pos if column == 'version'
    else
      return nil if column == 'version'
    end
    # 6 - workflow
    if dmsf_columns.include?('workflow')
      pos += 1
      return pos if column == 'workflow'
    else
      return nil if column == 'workflow'
    end
    # 7 - author
    if dmsf_columns.include?('author')
      pos += 1
      return pos if column == 'author'
    else
      return nil if column == 'author'
    end
    # 9 - custom fields
    DmsfFileRevisionCustomField.visible.each do |c|
      if DmsfFolder.is_column_on?(c.name)
        pos += 1
      end
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

  def get_locked_title
    if locked_for_user?
      if lock.reverse[0].user
        return l(:title_locked_by_user, user: lock.reverse[0].user)
      else
        return l(:notice_account_unknown_email)
      end
    end
    l(:title_unlock_file)
  end

  def issue
    unless @issue
      if system
        issue_id = title.to_i
        @issue = Issue.find_by(id: issue_id) if issue_id > 0
      end
    end
    @issue
  end

  def update_from_params(params)
    # Attributes
    self.title = params[:dmsf_folder][:title].strip
    self.description = params[:dmsf_folder][:description].strip
    self.dmsf_folder_id = params[:parent_id]
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
      if params[:permissions][:role_ids]
        params[:permissions][:role_ids].each do |role_id|
          permission = DmsfFolderPermission.new
          permission.object_id = role_id
          permission.object_type = Role.model_name.to_s
          dmsf_folder_permissions << permission
        end
      end
      if params[:permissions][:user_ids]
        params[:permissions][:user_ids].each do |user_id|
          permission = DmsfFolderPermission.new
          permission.object_id = user_id
          permission.object_type = User.model_name.to_s
          dmsf_folder_permissions << permission
        end
      end
    end
    # Save
    save
  end

  def self.get_valid_title(title)
    # 1. Invalid characters are replaced with dots.
    # 2. Two or more dots in a row are replaced with a single dot.
    # 3. Windows' WebClient does not like a dot at the end.
    title.gsub(/[#{INVALID_CHARACTERS}]/, '.').gsub(/\.{2,}/, '.').chomp('.')
  end

  def permission_for_role(role)
    self.dmsf_folder_permissions.roles.exists?(object_id: role.id)
  end

  def permissions_users
    Principal.active.where(id: self.dmsf_folder_permissions.users.map{ |p| p.object_id })
  end

  def inherited_permissions_from
    folder = self.dmsf_folder
    if folder
      if folder.dmsf_folder_permissions.any?
        folder
      else
        folder.inherited_permissions_from
      end
    else
      nil
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
          if issue_id > 0
            issue = Issue.find_by(id: issue_id)
            issue && !issue.visible?(User.current)
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
      if title =~ /^\./
        classes << 'dmsf-system'
      else
        classes << 'hascontextmenu'
        if type =~ /link$/
          classes << 'dmsf-gray'
        end
      end
    else
      classes << 'dmsf-tree'
      if %(folder project).include?(type)
        classes << 'dmsf-collapsed'
        classes << 'dmsf-not-loaded'
      else
        classes << 'dmsf-child'
      end
      if title =~ /^\./
        classes << 'dmsf-system'
      else
        if (type != 'project')
          classes << 'hascontextmenu'
          classes << 'dmsf-draggable'
        end
        if %(project folder).include?(type)
          classes << 'dmsf-droppable'
        end
        if type =~ /link$/
          classes << 'dmsf-gray'
        end
      end
    end
    classes.join ' '
  end

  def empty?
    !(dmsf_folders.visible.exists? || dmsf_files.visible.exists? || dmsf_links.visible.exists?)
  end

  private

  def self.directory_subtree(tree, folder, level, current_folder)
    folders = folder.dmsf_folders.visible.to_a
    folders.delete current_folder
    folders.delete_if { |f| f.locked_for_user? }
    folders.each do |subfolder|
      unless subfolder == current_folder
        tree.push ["#{'...' * level}#{subfolder.title}", subfolder.id]
        DmsfFolder.directory_subtree tree, subfolder, level + 1, current_folder
      end
    end
  end

end
