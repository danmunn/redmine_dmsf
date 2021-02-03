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

class DmsfLink < ActiveRecord::Base

  include ActiveModel::Validations

  belongs_to :project
  belongs_to :dmsf_folder
  belongs_to :deleted_by_user, class_name: 'User', foreign_key: 'deleted_by_user_id'
  belongs_to :user

  validates :name, presence: true, length: { maximum: 255 }
  # There can be project_id = -1 when attaching links to an issue. The project_id is assigned later when saving the
  # issue.
  #validates :project, presence: true
  validates :external_url, length: { maximum: 255 }
  validates :external_url, dmsf_url: true

  STATUS_DELETED = 1
  STATUS_ACTIVE = 0

  scope :visible, -> { where(deleted: STATUS_ACTIVE) }
  scope :deleted, -> { where(deleted: STATUS_DELETED) }

  def target_folder_id
    if target_type == DmsfFolder.model_name.to_s
      target_id
    else
      dmsf_folder_ids = DmsfFile.where(id: target_id).pluck(:dmsf_folder_id)
      dmsf_folder_ids.first
    end
  end

  def target_folder
    unless @target_folder
      if target_folder_id
        @target_folder = DmsfFolder.find_by(id: target_folder_id)
      end
    end
    @target_folder
  end

  def target_file_id
    target_id if target_type == DmsfFile.model_name.to_s
  end

  def target_file
    unless @target_file
      if target_file_id
        @target_file = DmsfFile.find_by(id: target_file_id)
      end
    end
    @target_file
  end

  def target_project
    unless @target_project
      @target_project = Project.find_by(id: target_project_id)
    end
    @target_project
  end

  def title
    name
  end

  def self.find_link_by_file_name(project, folder, filename)
    links = DmsfLink.where(
      project_id: project.id,
      dmsf_folder_id: folder ? folder.id : nil,
      target_type: DmsfFile.model_name.to_s).visible.all
    links.each do |link|
      return link if link.target_file && (link.target_file.name == filename)
    end
    nil
  end

  def path
    if target_type == DmsfFile.model_name.to_s
      path = target_file.dmsf_path.map { |element| element.is_a?(DmsfFile) ? element.display_name : element.title }.join('/') if target_file
    else
      path = target_folder ? target_folder.dmsf_path_str : +''
    end
    path.insert(0, "#{target_project.name}:") if project_id != target_project_id
    if path && path.length > 50
      return "#{path[0, 25]}...#{path[-25, 25]}"
    end
    path
  end

  def move_to(target_project, target_folder)
    self.project = target_project
    self.dmsf_folder = target_folder
    save
  end

  def copy_to(project, folder)
    link = DmsfLink.new
    link.target_project_id = target_project_id
    link.target_id = target_id
    link.target_type = target_type
    link.name = name
    link.external_url = external_url
    link.project_id = project.id
    link.dmsf_folder_id = folder ? folder.id : nil
    link.save!
    link
  end

  def delete(commit = false)
    if commit
      destroy
    else
      self.deleted = STATUS_DELETED
      self.deleted_by_user = User.current
      save validate: false
    end
  end

  def restore
    if dmsf_folder_id && (dmsf_folder.nil? || dmsf_folder.deleted?)
      errors[:base] << l(:error_parent_folder)
      return false
    end
    self.deleted = STATUS_ACTIVE
    self.deleted_by_user = nil
    save validate: false
  end

  def is_folder?
    target_type == 'DmsfFolder'
  end

  def is_file?
    !is_folder?
  end

end
