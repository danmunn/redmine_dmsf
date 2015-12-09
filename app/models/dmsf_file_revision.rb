# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
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

class DmsfFileRevision < ActiveRecord::Base
  unloadable
  belongs_to :file, :class_name => 'DmsfFile', :foreign_key => 'dmsf_file_id'
  belongs_to :source_revision, :class_name => 'DmsfFileRevision', :foreign_key => 'source_dmsf_file_revision_id'
  belongs_to :user
  belongs_to :folder, :class_name => 'DmsfFolder', :foreign_key => 'dmsf_folder_id'
  belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'
  has_many :access, :class_name => 'DmsfFileRevisionAccess', :foreign_key => 'dmsf_file_revision_id', :dependent => :destroy
  has_many :dmsf_workflow_step_assignment, :dependent => :destroy  
  accepts_nested_attributes_for :access, :dmsf_workflow_step_assignment, :file, :user   
  
  # Returns a list of revisions that are not deleted here, or deleted at parent level either
  scope :visible, -> { where(deleted: false) }
  scope :deleted, -> { where(deleted: true) }  

  acts_as_customizable
  acts_as_event :title => Proc.new {|o| "#{l(:label_dmsf_updated)}: #{o.file.dmsf_path_str}"},
    :url => Proc.new {|o| {:controller => 'dmsf_files', :action => 'show', :id => o.file}},
    :datetime => Proc.new {|o| o.updated_at },
    :description => Proc.new {|o| o.comment },
    :author => Proc.new {|o| o.user }
  
  acts_as_activity_provider :type => 'dmsf_file_revisions',
    :timestamp => "#{DmsfFileRevision.table_name}.updated_at",
    :author_key => "#{DmsfFileRevision.table_name}.user_id",
    :permission => :view_dmsf_file_revisions,
    :scope => select("#{DmsfFileRevision.table_name}.*").
      joins(
        "INNER JOIN #{DmsfFile.table_name} ON #{DmsfFileRevision.table_name}.dmsf_file_id = #{DmsfFile.table_name}.id " +
        "INNER JOIN #{Project.table_name} ON #{DmsfFile.table_name}.project_id = #{Project.table_name}.id").
      where("#{DmsfFile.table_name}.deleted = :false", {:false => false})  

  validates :title, :presence => true  
  validates_format_of :name, :with => DmsfFolder.invalid_characters,
    :message => l(:error_contains_invalid_character)

  def project
    self.file.project if self.file
  end

  def folder
    self.file.folder if self.file
  end

  def self.remove_extension(filename)
    filename[0, (filename.length - File.extname(filename).length)]
  end

  def self.filename_to_title(filename)
    remove_extension(filename).gsub(/_+/, ' ');
  end

  def delete(commit = false, force = true)
    if self.file.locked_for_user?
      errors[:base] << l(:error_file_is_locked)
      return false
    end
    if !commit && (!force && (self.file.revisions.length <= 1))
      errors[:base] << l(:error_at_least_one_revision_must_be_present)
      return false
    end
    dependent = DmsfFileRevision.where(:source_dmsf_file_revision_id => self.id).all
    dependent.each do |d|
      d.source_revision = self.source_revision
      d.save!
    end
    if commit
      self.destroy
    else
      self.deleted = true
      self.deleted_by_user = User.current
      save
    end
  end

  def restore
    self.deleted = false
    self.deleted_by_user = nil
    save
  end

  def destroy
    if Setting.plugin_redmine_dmsf['dmsf_really_delete_files']
      dependencies = DmsfFileRevision.where(:disk_filename => self.disk_filename).all.count
      File.delete(self.disk_file) if dependencies <= 1 && File.exist?(self.disk_file)
    end
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
    access.select('user_id, COUNT(*) AS count, MIN(created_at) AS first_at, MAX(created_at) AS last_at').group('user_id')
  end

  def version
    "#{self.major_version}.#{self.minor_version}"
  end

  def disk_file(project = nil)
    project = self.file.project unless project
    storage_base = DmsfFile.storage_path.dup
    if self.file && project
      project_base = project.identifier.gsub(/[^\w\.\-]/,'_')
      storage_base << "/p_#{project_base}"
    end
    Dir.mkdir(storage_base) unless File.exists?(storage_base)
    "#{storage_base}/#{self.disk_filename}"
  end

  def detect_content_type
    content_type = self.mime_type
    content_type = Redmine::MimeType.of(self.disk_filename) if content_type.blank?
    content_type = 'application/octet-stream' if content_type.blank?
    content_type.to_s
  end

  def clone
    new_revision = DmsfFileRevision.new
    new_revision.file = self.file
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

  def increase_version(version_to_increase, new_content)
    if new_content
      self.minor_version = case version_to_increase
        when 2 then 0
        else self.minor_version + 1
      end
    else
      self.minor_version = case version_to_increase
        when 1 then self.minor_version + 1
        when 2 then 0
        else self.minor_version
      end
    end

    self.major_version = case version_to_increase
      when 2 then self.major_version + 1
      else self.major_version
    end
  end

  def new_storage_filename
    raise DmsfAccessError, 'File id is not set' unless self.file.id
    filename = DmsfHelper.sanitize_filename(self.name)
    timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
    while File.exist?(File.join(DmsfFile.storage_path, "#{timestamp}_#{self.file.id}_#{filename}"))
      timestamp.succ!
    end
    "#{timestamp}_#{self.file.id}_#{filename}"
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
    format.sub!('%t', filename)
    format.sub!('%d', self.updated_at.strftime('%Y%m%d%H%M%S'))
    format.sub!('%v', self.version)
    format.sub!('%i', self.file.id.to_s)
    format.sub!('%r', self.id.to_s)
    format + ext
  end

end
