# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
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

require 'digest'

class DmsfFileRevision < ActiveRecord::Base

  belongs_to :dmsf_file
  belongs_to :source_revision, class_name: 'DmsfFileRevision', foreign_key: 'source_dmsf_file_revision_id'
  belongs_to :user
  belongs_to :deleted_by_user, class_name: 'User', foreign_key: 'deleted_by_user_id'
  belongs_to :dmsf_workflow_started_by_user, class_name: 'User', foreign_key: 'dmsf_workflow_started_by_user_id'
  belongs_to :dmsf_workflow_assigned_by_user, class_name: 'User', foreign_key: 'dmsf_workflow_assigned_by_user_id'
  belongs_to :dmsf_workflow
  has_many :dmsf_file_revision_access, dependent: :destroy
  has_many :dmsf_workflow_step_assignment, dependent: :destroy

  STATUS_DELETED = 1
  STATUS_ACTIVE = 0

  PROTOCOLS = {
    'application/msword' => 'ms-word',
    'application/excel' => 'ms-excel',
    'application/vnd.ms-excel' => 'ms-excel',
    'application/vnd.ms-powerpoint' => 'ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'ms-word',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'ms-excel',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow' => 'ms-powerpoint',
    'application/vnd.oasis.opendocument.spreadsheet' => 'ms-excel',
    'application/vnd.oasis.opendocument.text' => 'ms-word',
    'application/vnd.oasis.opendocument.presentation' => 'ms-powerpoint',
    'application/vnd.ms-excel.sheet.macroEnabled.12' => 'ms-excel'
  }.freeze

  scope :visible, -> { where(deleted: STATUS_ACTIVE) }
  scope :deleted, -> { where(deleted: STATUS_DELETED) }

  acts_as_customizable
  acts_as_event title: Proc.new {|o| (o.source_dmsf_file_revision_id.present? ? "#{l(:label_dmsf_updated)}" : "#{l(:label_created)}") +
                                          ": #{o.dmsf_file.dmsf_path_str}"},
    url: Proc.new { |o| { controller: 'dmsf_files', action: 'show', id: o.dmsf_file } },
    datetime: Proc.new {|o| o.updated_at },
    description: Proc.new { |o| "#{o.description}\n#{o.comment}" },
    author: Proc.new { |o| o.user }

  acts_as_activity_provider type: 'dmsf_file_revisions',
    timestamp: "#{DmsfFileRevision.table_name}.updated_at",
    author_key: "#{DmsfFileRevision.table_name}.user_id",
    permission: :view_dmsf_file_revisions,
    scope: DmsfFileRevision.joins(:dmsf_file).
      joins("JOIN #{Project.table_name} ON #{Project.table_name}.id = #{DmsfFile.table_name}.project_id").visible

  validates :title, presence: true
  validates :major_version, presence: true
  validates :minor_version, presence: true
  validates :dmsf_file, presence: true
  validates :name, dmsf_file_name: true
  validates :description, length: { maximum: 1.kilobyte }
  validates :size, dmsf_max_file_size: true

  def project
    dmsf_file.project if dmsf_file
  end

  def folder
    dmsf_file.dmsf_folder if dmsf_file
  end

  def self.remove_extension(filename)
    filename[0, (filename.length - File.extname(filename).length)]
  end

  def self.filename_to_title(filename)
    remove_extension(filename).gsub(/_+/, ' ');
  end
 
  def self.easy_activity_custom_project_scope(scope, options, _)
    scope.where(dmsf_files: { project_id: options[:project_ids] })
  end

  def delete(commit = false, force = true)
    if dmsf_file.locked_for_user?
      errors[:base] << l(:error_file_is_locked)
      return false
    end
    if !commit && (!force && (dmsf_file.dmsf_file_revisions.length <= 1))
      errors[:base] << l(:error_at_least_one_revision_must_be_present)
      return false
    end

    if commit
      destroy
    else
      self.deleted = DmsfFile::STATUS_DELETED
      self.deleted_by_user = User.current
      save
    end
  end

  def obsolete
    if dmsf_file.locked_for_user?
      errors[:base] << l(:error_file_is_locked)
      return false
    end
    self.workflow = DmsfWorkflow::STATE_OBSOLETE
    save
  end

  def restore
    self.deleted = DmsfFile::STATUS_ACTIVE
    self.deleted_by_user = nil
    save
  end

  def destroy
    DmsfFileRevision.where(source_dmsf_file_revision_id: id).find_each do |d|
      d.source_revision = source_revision
      d.save!
    end
    if Setting.plugin_redmine_dmsf['dmsf_really_delete_files']
      dependencies = DmsfFileRevision.where(disk_filename: disk_filename).all.size
      FileUtils.rm_f(disk_file) if dependencies <= 1
    end
    super
  end

  def version
    DmsfFileRevision.version major_version, minor_version
  end

  def self.version(major_version, minor_version)
    if major_version && minor_version
      ver = DmsfUploadHelper::gui_version(major_version).to_s
      if -minor_version != ' '.ord
        ver << ".#{DmsfUploadHelper::gui_version(minor_version)}"
      end
      ver
    end
  end
  
  def storage_base_path
    time = created_at || DateTime.current
    DmsfFile.storage_path.join(time.strftime('%Y')).join(time.strftime('%m'))
  end

  def disk_file(search_if_not_exists = true)
    path = storage_base_path
    begin
      FileUtils.mkdir_p(path) unless File.exist?(path)
    rescue => e
      Rails.logger.error e.message
    end
    filename = path.join(disk_filename)
    if search_if_not_exists
      unless File.exist?(filename)
        # Let's search for the physical file in source revisions
        dmsf_file.dmsf_file_revisions.where(['created_at < ?', created_at]).order(created_at: :desc).each do |rev|
          filename = rev.disk_file
          break if File.exist?(filename)
        end
      end
    end
    filename
  end

  def new_storage_filename
    raise DmsfAccessError, 'File id is not set' unless dmsf_file&.id
    filename = DmsfHelper.sanitize_filename(name)
    timestamp = DateTime.current.strftime('%y%m%d%H%M%S')
    while File.exist?(storage_base_path.join("#{timestamp}_#{dmsf_file.id}_#{filename}"))
      timestamp.succ!
    end
    "#{timestamp}_#{dmsf_file.id}_#{filename}"
  end

  def detect_content_type
    content_type = mime_type
    content_type = Redmine::MimeType.of(disk_filename) if content_type.blank?
    content_type = 'application/octet-stream' if content_type.blank?
    content_type
  end

  def clone
    new_revision = DmsfFileRevision.new
    new_revision.dmsf_file = dmsf_file
    new_revision.disk_filename = disk_filename
    new_revision.size = size
    new_revision.mime_type = mime_type
    new_revision.title = title
    new_revision.description = description
    new_revision.workflow = workflow
    new_revision.major_version = major_version
    new_revision.minor_version = minor_version
    new_revision.source_revision = self
    new_revision.user = User.current
    new_revision.name = name
    new_revision.digest = digest
    new_revision
  end

  def workflow_str(name)
    str = ''
    if name && dmsf_workflow_id
      names = DmsfWorkflow.where(id: dmsf_workflow_id).pluck(:name)
      str = "#{names.first} - " if names.any?
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
      when DmsfWorkflow::STATE_OBSOLETE
        str + l(:title_obsolete)
      else
        str + l(:title_none)
    end
  end

  def set_workflow(dmsf_workflow_id, commit)
    self.dmsf_workflow_id = dmsf_workflow_id
    if commit == 'start'
      self.workflow = DmsfWorkflow::STATE_WAITING_FOR_APPROVAL
      self.dmsf_workflow_started_by_user = User.current
      self.dmsf_workflow_started_at = DateTime.current
    else
      self.workflow = DmsfWorkflow::STATE_ASSIGNED
      self.dmsf_workflow_assigned_by_user = User.current
      self.dmsf_workflow_assigned_at = DateTime.current
    end
  end

  def assign_workflow(dmsf_workflow_id)
    wf = DmsfWorkflow.find_by(id: dmsf_workflow_id)
    wf.assign(self.id) if wf && self.id
  end

  def increase_version(version_to_increase)
    self.minor_version = case version_to_increase
      when 1
        DmsfUploadHelper.increase_version(minor_version, 1)
      when 2
        (major_version < 0) ? -(' '.ord) : 0
      else
        minor_version
    end
    self.major_version = case version_to_increase
      when 2
        DmsfUploadHelper::increase_version(major_version, 1)
      else
        major_version
    end
  end

  def copy_file_content(open_file)
    sha = Digest::SHA256.new
    File.open(disk_file(false), 'wb') do |f|
      if open_file.respond_to?(:read)
        while (buffer = open_file.read(8192))
          f.write buffer
          sha.update buffer
        end
      else
        f.write open_file
        sha.update open_file
      end
    end
    self.digest = sha.hexdigest
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    DmsfFileRevisionCustomField.all
  end

  def iversion
    parts = version.split '.'
    parts.size == 2 ? parts[0].to_i * 1000 + parts[1].to_i : 0
  end

  def formatted_name(format)
    return name if format.blank?
    if name =~ /(.*)(\..*)$/
      filename = $1
      ext = $2
    else
      filename = name
    end
    format2 = format
    format2 = format2.sub('%t', title)
    format2 = format2.sub('%f', filename)
    format2 = format2.sub('%d', updated_at.strftime('%Y%m%d%H%M%S'))
    format2 = format2.sub('%v', version)
    format2 = format2.sub('%i', dmsf_file.id.to_s)
    format2 = format2.sub('%r', id.to_s)
    format2 += ext if ext
    format2
  end

  def create_digest
    begin
      self.digest = Digest::SHA256.file(path).hexdigest
    rescue => e
      Rails.logger.error e.message
      self.digest = 0
    end
  end

  # Returns either MD5 or SHA256 depending on the way self.digest was computed
  def digest_type
    digest.size < 64 ? 'MD5' : 'SHA256' if digest.present?
  end

  def tooltip
    if description.present?
      text = description
    else
      text = +''
    end
    if comment.present?
      text += ' / ' if text.present?
      text += comment
    end
    ActionView::Base.full_sanitizer.sanitize(text)
  end

  def workflow_tooltip
    tooltip = +''
    if dmsf_workflow
      case workflow
        when DmsfWorkflow::STATE_WAITING_FOR_APPROVAL, DmsfWorkflow::STATE_ASSIGNED
          assignments = dmsf_workflow.next_assignments(id)
          if assignments
            assignments.each_with_index do |assignment, index|
              tooltip << ', ' if index > 0
              tooltip << assignment.user.name
            end
          end
        when DmsfWorkflow::STATE_APPROVED, DmsfWorkflow::STATE_REJECTED
          action = DmsfWorkflowStepAction.joins(:dmsf_workflow_step_assignment).where(
            dmsf_workflow_step_assignments: { dmsf_file_revision_id: id }).order(
            'dmsf_workflow_step_actions.created_at').last
          tooltip << action.author.name if action
      end
    end
    tooltip
  end

  def protocol
    unless @protocol
      @protocol = PROTOCOLS[mime_type]
    end
    @protocol
  end

end
