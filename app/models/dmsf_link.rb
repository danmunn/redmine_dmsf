# encode: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-15 Karel Pičman <karel.picman@kontron.com>
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

class DmsfLink < ActiveRecord::Base
  unloadable
  include ActiveModel::Validations

  belongs_to :project
  belongs_to :dmsf_folder
  belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'
  belongs_to :user

  validates :name, :presence => true
  validates_length_of :name, :maximum => 255
  validates_length_of :external_url, :maximum => 255  
  validate :validate_url
  
  def validate_url
    if self.target_type == 'DmsfUrl'
      begin 
        URI.parse self.external_url
      rescue URI::InvalidURIError        
        errors.add :external_url, :invalid
      end      
    end
  end
  
  scope :visible, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }

  def target_folder_id
    if self.target_type == DmsfFolder.model_name.to_s
      self.target_id
    else
      f = DmsfFile.find_by_id self.target_id
      f.dmsf_folder_id if f
    end
  end

  def target_folder
    DmsfFolder.find_by_id self.target_folder_id if self.target_folder_id
  end

  def target_file_id
    self.target_id if self.target_type == DmsfFile.model_name.to_s
  end

  def target_file
    DmsfFile.find_by_id self.target_file_id if self.target_file_id
  end

  def target_project
    Project.find_by_id self.target_project_id
  end

  def folder
    DmsfFolder.find_by_id self.dmsf_folder_id
  end

  def title
    self.name
  end

  def self.find_link_by_file_name(project, folder, filename)
    links = DmsfLink.where(
      :project_id => project.id,
      :dmsf_folder_id => folder ? folder.id : nil,
      :target_type => DmsfFile.model_name.to_s).visible.all
    links.each do |link|
      return link if link.target_file.name == filename
    end
    nil
  end

  def path
    if self.target_type == DmsfFile.model_name.to_s  
      path = self.target_file.dmsf_path.map { |element| element.is_a?(DmsfFile) ? element.name : element.title }.join('/') if self.target_file
    else      
      path = self.target_folder ? self.target_folder.dmsf_path_str : ''
    end
    path.insert(0, "#{self.target_project.name}:") if self.project_id != self.target_project_id
    if path && path.length > 50
      return "#{path[0, 25]}...#{path[-25, 25]}"
    end
    path
  end

  def copy_to(project, folder)
    link = DmsfLink.new(
      :target_project_id => self.target_project_id,
      :target_id => self.target_id,
      :target_type => self.target_type,
      :name => self.name,
      :external_url => self.external_url,
      :project_id => project.id,
      :dmsf_folder_id => folder ? folder.id : nil)
    link.save
    link
  end

  def delete(commit = false)
    if commit
      self.destroy
    else
      self.deleted = true
      self.deleted_by_user = User.current
      save
    end
  end

  def restore
    if self.dmsf_folder_id && (self.folder.nil? || self.folder.deleted)
      errors[:base] << l(:error_parent_folder)
      return false
    end
    self.deleted = false
    self.deleted_by_user = nil
    save
  end

end
