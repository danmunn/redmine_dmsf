# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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
  
  cattr_reader :invalid_characters
  @@invalid_characters = /\A[^\/\\\?":<>]*\z/
  
  belongs_to :project
  belongs_to :folder, :class_name => "DmsfFolder", :foreign_key => "dmsf_folder_id"
  has_many :subfolders, :class_name => "DmsfFolder", :foreign_key => "dmsf_folder_id", :order => "title ASC"
  has_many :files, :class_name => "DmsfFile", :foreign_key => "dmsf_folder_id",
           :conditions => { :deleted => false }
  belongs_to :user

  acts_as_customizable
  
  validates_presence_of :title
  validates_uniqueness_of :title, :scope => [:dmsf_folder_id, :project_id]
  
  validates_format_of :title, :with => @@invalid_characters,
    :message => l(:error_contains_invalid_character)
  
  validate :check_cycle
  
  acts_as_event :title => Proc.new {|o| o.title},
                :description => Proc.new {|o| o.description },
                :url => Proc.new {|o| {:controller => "dmsf", :action => "show", :id => o.project, :folder_id => o}},
                :datetime => Proc.new {|o| o.updated_at },
                :author => Proc.new {|o| o.user }
  
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
  
  def self.project_root_folders(project)
    find(:all, :conditions => 
        ["dmsf_folder_id is NULL and project_id = :project_id", {:project_id => project.id}], :order => "title ASC")
  end
  
  def self.find_by_title(project, folder, title)
    if folder.nil?
      find(:first, :conditions => 
        ["dmsf_folder_id is NULL and project_id = :project_id and title = :title", 
          {:project_id => project.id, :title => title}])
    else
      find(:first, :conditions => 
        ["dmsf_folder_id = :folder_id and title = :title", 
          {:project_id => project.id, :folder_id => folder.id, :title => title}])
    end
  end
  
  def delete
    return false if !self.subfolders.empty? || !self.files.empty?
    destroy
  end
  
  def dmsf_path
    folder = self
    path = []
    while !folder.nil?
      path.unshift(folder)
      folder = folder.folder
    end 
    path
  end
  
  def dmsf_path_str
    path = self.dmsf_path
    string_path = path.map { |element| element.title }
    string_path.join("/")
  end
  
  def notify?
    return true if self.notification
    return true if folder && folder.notify?
    return false
  end
  
  def notify_deactivate
    self.notification = false
    self.save!
  end
  
  def notify_activate
    self.notification = true
    self.save!
  end
  
  def self.directory_tree(project, current_folder = nil)
    tree = [[l(:link_documents), nil]]
    DmsfFolder.project_root_folders(project).each do |folder|
      unless folder == current_folder
        tree.push(["...#{folder.title}", folder.id])
        directory_subtree(tree, folder, 2, current_folder)
      end
    end
    return tree
  end

  def deep_file_count
    file_count = self.files.length
    self.subfolders.each {|subfolder| file_count += subfolder.deep_file_count}
    file_count
  end
  
  def deep_folder_count    
    folder_count = self.subfolders.length
    self.subfolders.each {|subfolder| folder_count += subfolder.deep_folder_count}
    folder_count    
  end
  
  def self.project_deep_folder_count(project)    
    subfolders = self.project_root_folders(project) 
    folder_count = subfolders.length 
    subfolders.each{|subfolder| folder_count += subfolder.deep_folder_count}
    folder_count
  end
  
  def self.project_deep_file_count(project)
    file_count = DmsfFile.project_root_files(project).length
    self.project_root_folders(project).each{|subfolder| file_count += subfolder.deep_file_count}
    file_count
  end

  def deep_size
    size = 0
    self.files.each {|file| size += file.size}
    self.subfolders.each {|subfolder| size += subfolder.deep_size}
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

    #copy only cfs present in destination project
    temp_custom_values = self.custom_values.select{|cv| new_folder.project.all_dmsf_custom_fields.include?(cv.custom_field)}.map(&:clone)
    
    new_folder.custom_values = temp_custom_values

    #add default value for CFs not existing
    present_custom_fields = new_folder.custom_values.collect(&:custom_field).uniq
    new_folder.project.all_dmsf_custom_fields.each do |cf|
      unless present_custom_fields.include?(cf)
        new_folder.custom_values << CustomValue.new({:custom_field => cf, :value => cf.default_value})
      end
    end

    return new_folder unless new_folder.save
    
    self.files.each do |f|
      f.copy_to(project, new_folder)
    end
    
    self.subfolders.each do |s|
      s.copy_to(project, new_folder)
    end
    
    return new_folder
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    search_project = nil
    if self.project.present?
      search_project = self.project
    elsif self.project_id.present?
      search_project = Project.find(self.project_id)
    end
    if search_project
      search_project.all_dmsf_custom_fields
    else
      DmsfFileRevisionCustomField.all
    end
  end

  # To fullfill searchable module expectations
  def self.search(tokens, projects=nil, options={})
    tokens = [] << tokens unless tokens.is_a?(Array)
    projects = [] << projects unless projects.nil? || projects.is_a?(Array)
    
    find_options = {:include => [:project]}
    find_options[:order] = "dmsf_folders.updated_at " + (options[:before] ? 'DESC' : 'ASC')
    
    limit_options = {}
    limit_options[:limit] = options[:limit] if options[:limit]
    if options[:offset]
      limit_options[:conditions] = "(dmsf_folders.updated_at " + (options[:before] ? '<' : '>') + "'#{connection.quoted_date(options[:offset])}')"
    end
    
    columns = options[:titles_only] ? ["dmsf_folders.title"] : ["dmsf_folders.title", "dmsf_folders.description"]
            
    token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ?)"}
    
    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')
    find_options[:conditions] = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]
    
    project_conditions = []
    project_conditions << (Project.allowed_to_condition(User.current, :view_dmsf_files))
    project_conditions << "project_id IN (#{projects.collect(&:id).join(',')})" unless projects.nil?
    
    results = []
    results_count = 0
    
    with_scope(:find => {:conditions => [project_conditions.join(' AND ')]}) do
      with_scope(:find => find_options) do
        results_count = count(:all)
        results = find(:all, limit_options)
      end
    end
    
    [results, results_count]
  end

  private
  
  def self.directory_subtree(tree, folder, level, current_folder)
    folder.subfolders.each do |subfolder|
      unless subfolder == current_folder
        tree.push(["#{"..." * level}#{subfolder.title}", subfolder.id])
        directory_subtree(tree, subfolder, level + 1, current_folder)
      end
    end
  end
  
end

