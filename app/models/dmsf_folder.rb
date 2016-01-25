# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-15 Karel Pičman <karel.picman@konton.com>
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
  unloadable

  include RedmineDmsf::Lockable

  cattr_reader :invalid_characters
  @@invalid_characters = /\A[^\/\\\?":<>]*\z/    

  belongs_to :project
  belongs_to :folder, :class_name => 'DmsfFolder', :foreign_key => 'dmsf_folder_id'
  belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'
  belongs_to :user

  has_many :subfolders, :class_name => 'DmsfFolder', :foreign_key => 'dmsf_folder_id',
    :dependent => :destroy
  has_many :files, :class_name => 'DmsfFile', :foreign_key => 'dmsf_folder_id',
    :dependent => :destroy  
  has_many :folder_links, -> { where :target_type => 'DmsfFolder' },
    :class_name => 'DmsfLink', :foreign_key => 'dmsf_folder_id', :dependent => :destroy
  has_many :file_links, -> { where :target_type => 'DmsfFile' },
    :class_name => 'DmsfLink', :foreign_key => 'dmsf_folder_id', :dependent => :destroy
  has_many :url_links, -> { where :target_type => 'DmsfUrl' },
    :class_name => 'DmsfLink', :foreign_key => 'dmsf_folder_id', :dependent => :destroy
  has_many :referenced_links, -> { where :target_type => 'DmsfFolder' },
    :class_name => 'DmsfLink', :foreign_key => 'target_id', :dependent => :destroy
  has_many :locks, -> { where(entity_type:  1).order("#{DmsfLock.table_name}.updated_at DESC") },
    :class_name => 'DmsfLock', :foreign_key => 'entity_id', :dependent => :destroy
  accepts_nested_attributes_for :user, :project, :folder, :subfolders, :files, :folder_links, :file_links, :url_links, :referenced_links, :locks  
  
  scope :visible, lambda { |*args|
    where(deleted: false) 
  }
  scope :deleted, lambda { |*args|
    where(deleted: true)
  }  

  acts_as_customizable
    
  acts_as_searchable :columns => ["#{self.table_name}.title", "#{self.table_name}.description"],
        :project_key => 'project_id',
        :date_column => 'updated_at',
        :permission => :view_dmsf_files,
        :scope => self.joins(:project)  
        
  acts_as_event :title => Proc.new {|o| o.title},
          :description => Proc.new {|o| o.description },
          :url => Proc.new {|o| {:controller => 'dmsf', :action => 'show', :id => o.project, :folder_id => o}},
          :datetime => Proc.new {|o| o.updated_at },
          :author => Proc.new {|o| o.user }

  validates :title, :presence => true
  validates_uniqueness_of :title, :scope => [:dmsf_folder_id, :project_id, :deleted], 
    conditions: -> { where.not(deleted: true) }
  validates_format_of :title, :with => @@invalid_characters,
    :message => l(:error_contains_invalid_character)
  validate :check_cycle

  before_create :default_values
  def default_values
    @notifications = Setting.plugin_redmine_dmsf['dmsf_default_notifications']
    if @notifications == '1'
      self.notification = true
    else
      self.notification = nil
    end
  end

  def check_cycle
    folders = []
    self.subfolders.each {|f| folders.push(f)}
    folders.each do |folder|
      if folder == self.folder
        errors.add(:folder, l(:error_create_cycle_in_folder_dependency))
        return false
      end
      folder.subfolders.each {|f| folders.push(f)}
    end
    return true
  end

  def self.find_by_title(project, folder, title)
    if folder
      visible.where(:project_id => project.id, :dmsf_folder_id => nil, :title => title).first
    else
      visible.where(:project_id => project.id, :dmsf_folder_id => folder.id, :title => title).first
    end
  end

  def delete(commit)
    if self.locked?
      errors[:base] << l(:error_folder_is_locked)
      return false
    elsif !self.subfolders.visible.empty? || !self.files.visible.empty?
      errors[:base] << l(:error_folder_is_not_empty)
      return false
    end
    self.referenced_links.each { |l| l.delete(commit) }
    if commit
      self.destroy
    else
      self.deleted = true
      self.deleted_by_user = User.current
      self.save
    end
  end

  def restore
    if self.dmsf_folder_id && (self.folder.nil? || self.folder.deleted)
      errors[:base] << l(:error_parent_folder)
      return false
    end
    self.referenced_links.each { |l| l.restore }
    self.deleted = false
    self.deleted_by_user = nil
    self.save
  end

  def dmsf_path
    folder = self
    path = []
    while folder
      path.unshift(folder)
      folder = folder.folder
    end
    path
  end

  def dmsf_path_str
    path = self.dmsf_path
    string_path = path.map { |element| element.title }
    string_path.join('/')
  end

  def notify?
    return true if self.notification
    return true if folder && folder.notify?
    return true if !folder && self.project.dmsf_notification
    return false
  end

  def notify_deactivate
    self.notification = nil
    self.save!
  end

  def notify_activate
    self.notification = true
    self.save!
  end

  def self.directory_tree(project, current_folder = nil)
    tree = [[l(:link_documents), nil]]
    project.dmsf_folders.visible.each do |folder|
      unless folder == current_folder
        tree.push(["...#{folder.title}", folder.id])
        directory_subtree(tree, folder, 2, current_folder)
      end
    end
    return tree
  end

  def folder_tree
    tree = [[self.title, self.id]]
    DmsfFolder.directory_subtree(tree, self, 2, nil)
    return tree
  end

  def self.file_list(files)
    options = Array.new
    options.push ['', nil, :label => 'none']
    files.each do |f|
      options.push [f.title, f.id]
    end
    options
  end

  def deep_file_count
    file_count = self.files.visible.count
    self.subfolders.visible.each {|subfolder| file_count += subfolder.deep_file_count}
    file_count + self.file_links.visible.count
  end

  def deep_folder_count
    folder_count = self.subfolders.visible.count
    self.subfolders.visible.each {|subfolder| folder_count += subfolder.deep_folder_count}
    folder_count + self.folder_links.visible.count
  end

  def deep_size
    size = 0
    self.files.visible.each {|file| size += file.size}
    self.subfolders.visible.each {|subfolder| size += subfolder.deep_size}
    size
  end

  # Returns an array of projects that current user can copy folder to
  def self.allowed_target_projects_on_copy
    projects = []
    if User.current.admin?
      projects = Project.visible.all
    elsif User.current.logged?
      User.current.memberships.each {|m| projects << m.project if m.roles.detect {|r| r.allowed_to?(:folder_manipulation) && r.allowed_to?(:file_manipulation)}}
    end
    projects
  end

  def copy_to(project, folder)
    new_folder = DmsfFolder.new
    new_folder.folder = folder ? folder : nil
    new_folder.project = folder ? folder.project : project
    new_folder.title = self.title
    new_folder.description = self.description
    new_folder.user = User.current

    new_folder.custom_values = []
    self.custom_values.each do |cv|
      new_folder.custom_values << CustomValue.new({:custom_field => cv.custom_field, :value => cv.value})
    end

    return new_folder unless new_folder.save

    self.files.visible.each do |f|
      f.copy_to project, new_folder
    end

    self.subfolders.visible.each do |s|
      s.copy_to project, new_folder
    end

    self.folder_links.visible.each do |l|
      l.copy_to project, new_folder
    end

    self.file_links.visible.each do |l|
      l.copy_to project, new_folder
    end

    self.url_links.visible.each do |l|
      l.copy_to project, new_folder
    end

    return new_folder
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    DmsfFileRevisionCustomField.all
  end
  
  def modified
    last_update = updated_at
    subfolders.each do |subfolder|
      last_update = subfolder.updated_at if subfolder.updated_at > last_update
    end
    files.each do |file|
      last_update = file.updated_at if file.updated_at > last_update
    end
    folder_links.each do |folder_link|
      last_update = folder_link.updated_at if folder_link.updated_at > last_update
    end
    file_links.each do |file_link|
      last_update = file_link.updated_at if file_link.updated_at > last_update
    end
    url_links.each do |url_link|
      last_update = url_link.updated_at if url_link.updated_at > last_update
    end
    last_update
  end
  
  # Number of items in the folder
  def items
    subfolders.visible.count +
    files.visible.count +
    folder_links.visible.count +
    file_links.visible.count +
    url_links.visible.count
  end 
    
  private

  def self.directory_subtree(tree, folder, level, current_folder)
    folder.subfolders.visible.each do |subfolder|
      unless subfolder == current_folder
        tree.push(["#{'...' * level}#{subfolder.title}", subfolder.id])
        directory_subtree(tree, subfolder, level + 1, current_folder)
      end
    end
  end

end