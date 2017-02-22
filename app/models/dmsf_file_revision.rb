# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

require 'digest/md5'

class DmsfFileRevision < ActiveRecord::Base

  unloadable
  belongs_to :dmsf_file
  belongs_to :source_revision, :class_name => 'DmsfFileRevision', :foreign_key => 'source_dmsf_file_revision_id'
  belongs_to :user
  belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'
  has_many :dmsf_file_revision_access, :dependent => :destroy
  has_many :dmsf_workflow_step_assignment, :dependent => :destroy

  STATUS_DELETED = 1
  STATUS_ACTIVE = 0

  scope :visible, -> { where(:deleted => STATUS_ACTIVE) }
  scope :deleted, -> { where(:deleted => STATUS_DELETED) }

  acts_as_customizable
  acts_as_event :title => Proc.new {|o| "#{l(:label_dmsf_updated)}: #{o.dmsf_file.dmsf_path_str}"},
    :url => Proc.new {|o| {:controller => 'dmsf_files', :action => 'show', :id => o.dmsf_file}},
    :datetime => Proc.new {|o| o.updated_at },
    :description => Proc.new {|o| o.comment },
    :author => Proc.new {|o| o.user }

  acts_as_activity_provider :type => 'dmsf_file_revisions',
    :timestamp => "#{DmsfFileRevision.table_name}.updated_at",
    :author_key => "#{DmsfFileRevision.table_name}.user_id",
    :permission => :view_dmsf_file_revisions,
    :scope => select("#{DmsfFileRevision.table_name}.*").
      joins(:dmsf_file).joins(
        "LEFT JOIN #{Project.table_name} ON #{DmsfFile.table_name}.container_id = #{Project.table_name}.id").
      where("#{DmsfFile.table_name}.container_type = ?", 'Project').visible

  validates :title, :presence => true
  validates_format_of :name, :with => DmsfFolder::INVALID_CHARACTERS,
    :message => l(:error_contains_invalid_character)

  def project
    self.dmsf_file.project if self.dmsf_file
  end

  def folder
    self.dmsf_file.dmsf_folder if self.dmsf_file
  end

  def self.remove_extension(filename)
    filename[0, (filename.length - File.extname(filename).length)]
  end

  def self.filename_to_title(filename)
    remove_extension(filename).gsub(/_+/, ' ');
  end

  def delete(commit = false, force = true)
    if self.dmsf_file.locked_for_user?
      errors[:base] << l(:error_file_is_locked)
      return false
    end
    if !commit && (!force && (self.dmsf_file.dmsf_file_revisions.length <= 1))
      errors[:base] << l(:error_at_least_one_revision_must_be_present)
      return false
    end

    if commit
      self.destroy
    else
      self.deleted = DmsfFile::STATUS_DELETED
      self.deleted_by_user = User.current
      save
    end
  end

  def restore
    self.deleted = DmsfFile::STATUS_ACTIVE
    self.deleted_by_user = nil
    save
  end

  def destroy
    dependent = DmsfFileRevision.where(:source_dmsf_file_revision_id => self.id).all
    dependent.each do |d|
      d.source_revision = self.source_revision
      d.save!
    end
    if Setting.plugin_redmine_dmsf['dmsf_really_delete_files']
      dependencies = DmsfFileRevision.where(:disk_filename => self.disk_filename).all.count
      File.delete(self.disk_file) if dependencies <= 1 && File.exist?(self.disk_file)
    end
    RedmineDmsf::Webdav::Cache.invalidate_item(propfind_cache_key)
    super
  end

  # In a static call, we find the first matched record on base object type and
  # then run the access_grouped call against it
  def self.access_grouped(revision_id)
    DmsfFileRevision.find(revision_id).first.access_grouped
  end

  # Get grouped data from dmsf_file_revision_access about file interactions
  # - 22-06-2012 - Rather than calling a static, we should use the access
  #   (has_many) to re-run a query - it makes more sense then executing
  #   custom SQL into a temporary object
  #
  def access_grouped
    self.dmsf_file_revision_access.select('user_id, COUNT(*) AS count, MIN(created_at) AS first_at, MAX(created_at) AS last_at').group('user_id')
  end

  def version
    "#{self.major_version}.#{self.minor_version}"
  end
  
  def storage_base_path(project = nil)
    project = self.dmsf_file.project unless project
    path = DmsfFile.storage_path.dup
    if self.dmsf_file && project
      project_base = project.identifier.gsub(/[^\w\.\-]/,'_')
      path << "/p_#{project_base}"
    end
  end

  def disk_file(project = nil)
    project = self.dmsf_file.project unless project
    path = storage_base_path(project)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    "#{path}/#{self.disk_filename}"
  end

  def detect_content_type
    content_type = self.mime_type
    content_type = Redmine::MimeType.of(self.disk_filename) if content_type.blank?
    content_type = 'application/octet-stream' if content_type.blank?
    content_type.to_s
  end

  def clone
    new_revision = DmsfFileRevision.new
    new_revision.dmsf_file = self.dmsf_file
    new_revision.disk_filename = self.disk_filename
    new_revision.size = self.size
    new_revision.mime_type = self.mime_type
    new_revision.title = self.title
    new_revision.description = self.description
    new_revision.workflow = self.workflow
    new_revision.major_version = self.major_version
    new_revision.minor_version = self.minor_version
    new_revision.source_revision = self
    new_revision.user = User.current
    new_revision.name = self.name
    new_revision.digest = self.digest
    new_revision
  end

  def workflow_str(name)
    str = ''
    if name && dmsf_workflow_id
      wf = DmsfWorkflow.find_by_id(dmsf_workflow_id)
      str = "#{wf.name} - " if wf
    end
    case workflow
      when DmsfWorkflow::STATE_WAITING_FOR_APPROVAL
        str + l(:title_waiting_for_approval)
      when DmsfWorkflow::STATE_APPROVED
        str + l(:title_approved)
      when DmsfWorkflow::STATE_ASSIGNED
        str + l(:title_assigned)
      when DmsfWorkflow::STATE_REJECTED
        str + l(:title_rejected)
      else
        str + l(:title_none)
    end
  end

  def set_workflow(dmsf_workflow_id, commit)
    self.dmsf_workflow_id = dmsf_workflow_id
    if commit == 'start'
      self.workflow = DmsfWorkflow::STATE_WAITING_FOR_APPROVAL
      self.dmsf_workflow_started_by = User.current.id if User.current
      self.dmsf_workflow_started_at = DateTime.now
    else
      self.workflow = DmsfWorkflow::STATE_ASSIGNED
      self.dmsf_workflow_assigned_by = User.current.id if User.current
      self.dmsf_workflow_assigned_at = DateTime.now
    end
  end

  def assign_workflow(dmsf_workflow_id)
    wf = DmsfWorkflow.find_by_id(dmsf_workflow_id)
    wf.assign(self.id) if wf && self.id
  end

  def increase_version(version_to_increase)
    self.minor_version = case version_to_increase
      when 1
        self.minor_version + 1
      when 2
        0
      else
        self.minor_version
    end
    self.major_version = case version_to_increase
      when 2
        self.major_version + 1
      else
        major_version
    end
  end

  def new_storage_filename
    raise DmsfAccessError, 'File id is not set' unless self.dmsf_file.id
    filename = DmsfHelper.sanitize_filename(self.name)
    timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
    while File.exist?(File.join(storage_base_path, "#{timestamp}_#{self.dmsf_file.id}_#{filename}"))
      timestamp.succ!
    end
    "#{timestamp}_#{self.dmsf_file.id}_#{filename}"
  end

  def copy_file_content(open_file)
    File.open(self.disk_file, 'wb') do |f|
      while (buffer = open_file.read(8192))
        f.write(buffer)
      end
    end
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    DmsfFileRevisionCustomField.all
  end

  def iversion
    parts = self.version.split '.'
    parts.size == 2 ? parts[0].to_i * 1000 + parts[1].to_i : 0
  end

  def formatted_name(format)
    return self.name if format.blank?
    if self.name =~ /(.*)(\..*)$/
      filename = $1
      ext = $2
    else
      filename = self.name
    end
    format2 = format.dup
    format2.sub!('%t', self.title)
    format2.sub!('%f', filename)
    format2.sub!('%d', self.updated_at.strftime('%Y%m%d%H%M%S'))
    format2.sub!('%v', self.version)
    format2.sub!('%i', self.dmsf_file.id.to_s)
    format2.sub!('%r', self.id.to_s)
    format2 += ext if ext
    format2
  end

  def self.create_digest(path)
    begin
      Digest::MD5.file(path).hexdigest
    rescue Exception => e
      Rails.logger.error e.message
      0
    end
  end

  def create_digest
    self.digest = DmsfFileRevision.create_digest(self.disk_file)
  end

  def tooltip
    text = ''
    text = self.description if self.description.present?
    if self.comment.present?
      text += ' / ' if text.present?
      text += self.comment
    end
    ActionView::Base.full_sanitizer.sanitize(text)
  end
  
  def save(*args)
    RedmineDmsf::Webdav::Cache.invalidate_item(propfind_cache_key)
    super(*args)
  end

  def save!(*args)
    RedmineDmsf::Webdav::Cache.invalidate_item(propfind_cache_key)
    super(*args)
  end
  
  def propfind_cache_key
    dmsf_file.propfind_cache_key
  end

end
