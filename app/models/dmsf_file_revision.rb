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

# File revision
class DmsfFileRevision < ApplicationRecord
  belongs_to :dmsf_file, inverse_of: :dmsf_file_revisions
  belongs_to :source_revision,
             class_name: 'DmsfFileRevision',
             foreign_key: 'source_dmsf_file_revision_id',
             inverse_of: false
  belongs_to :user
  belongs_to :deleted_by_user, class_name: 'User'
  belongs_to :dmsf_workflow_started_by_user, class_name: 'User'
  belongs_to :dmsf_workflow_assigned_by_user, class_name: 'User'
  belongs_to :dmsf_workflow

  has_many :dmsf_file_revision_access, dependent: :destroy
  has_many :dmsf_workflow_step_assignment, dependent: :destroy

  before_destroy :delete_source_revision

  STATUS_DELETED = 1
  STATUS_ACTIVE = 0

  PATCH_VERSION = 1
  MINOR_VERSION = 2
  MAJOR_VERSION = 3

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
    'application/vnd.ms-excel.sheet.macroenabled.12' => 'ms-excel'
  }.freeze

  scope :visible, -> { where(deleted: STATUS_ACTIVE) }
  scope :deleted, -> { where(deleted: STATUS_DELETED) }

  acts_as_customizable
  acts_as_event(
    title: proc { |o|
      if o.source_dmsf_file_revision_id.present?
        "#{l(:label_dmsf_updated)}: #{o.dmsf_file.dmsf_path_str}"
      else
        "#{l(:label_created)}: #{o.dmsf_file.dmsf_path_str}"
      end
    },
    url: proc { |o| { controller: 'dmsf_files', action: 'show', id: o.dmsf_file } },
    datetime: proc { |o| o.updated_at },
    description: proc { |o| "#{o.description}\n#{o.comment}" },
    author: proc { |o| o.user }
  )

  acts_as_activity_provider(
    type: 'dmsf_file_revisions',
    timestamp: "#{DmsfFileRevision.table_name}.updated_at",
    author_key: "#{DmsfFileRevision.table_name}.user_id",
    permission: :view_dmsf_file_revisions,
    scope: proc {
      DmsfFileRevision
        .joins(:dmsf_file)
        .joins("JOIN #{Project.table_name} ON #{Project.table_name}.id = #{DmsfFile.table_name}.project_id")
        .visible
    }
  )

  validates :title, presence: true
  validates :title, length: { maximum: 255 }
  validates :major_version, presence: true
  validates :name, dmsf_file_name: true
  validates :name, length: { maximum: 255 }
  validates :disk_filename, length: { maximum: 255 }
  validates :name, dmsf_file_extension: true
  validates :description, length: { maximum: 1.kilobyte }
  validates :size, dmsf_max_file_size: true

  def visible?(_user = nil)
    deleted == STATUS_ACTIVE
  end

  def project
    dmsf_file&.project
  end

  def folder
    dmsf_file&.dmsf_folder
  end

  def self.remove_extension(filename)
    filename[0, (filename.length - File.extname(filename).length)]
  end

  def self.filename_to_title(filename)
    remove_extension(filename).gsub(/_+/, ' ')
  end

  def self.easy_activity_custom_project_scope(scope, options, _)
    scope.where(dmsf_files: { project_id: options[:project_ids] })
  end

  def delete(commit: false, force: true)
    if dmsf_file.locked_for_user?
      errors.add :base, l(:error_file_is_locked)
      return false
    end
    if !commit && (!force && (dmsf_file.dmsf_file_revisions.length <= 1))
      errors.add :base, l(:error_at_least_one_revision_must_be_present)
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
      errors.add :base, l(:error_file_is_locked)
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

  def version
    DmsfFileRevision.version major_version, minor_version, patch_version
  end

  def self.version(major_version, minor_version, patch_version)
    return unless major_version

    ver = DmsfUploadHelper.gui_version(major_version).to_s
    if minor_version
      ver << ".#{DmsfUploadHelper.gui_version(minor_version)}" if -minor_version != ' '.ord
      ver << ".#{DmsfUploadHelper.gui_version(patch_version)}" if patch_version.present? && (-patch_version != ' '.ord)
    end
    ver
  end

  def storage_base_path
    time = created_at || DateTime.current
    DmsfFile.storage_path.join(time.strftime('%Y')).join time.strftime('%m')
  end

  def disk_file(search_if_not_exists: true)
    path = storage_base_path
    begin
      FileUtils.mkdir_p(path)
    rescue StandardError => e
      Rails.logger.error e.message
    end
    filename = path.join(disk_filename)
    if search_if_not_exists && !File.exist?(filename)
      # Let's search for the physical file in source revisions
      dmsf_file.dmsf_file_revisions.where(['created_at < ?', created_at]).order(created_at: :desc).each do |rev|
        filename = rev.disk_file
        break if File.exist?(filename)
      end
    end
    filename.to_s
  end

  def new_storage_filename
    raise RedmineDmsf::Errors::DmsfAccessError, 'File id is not set' unless dmsf_file&.id

    filename = DmsfHelper.sanitize_filename(name)
    timestamp = DateTime.current.strftime('%y%m%d%H%M%S')
    timestamp.succ! while File.exist? storage_base_path.join("#{timestamp}_#{dmsf_file.id}_#{filename}")
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
    new_revision.patch_version = patch_version
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
    wf.assign(id) if wf && id
  end

  def increase_version(version_to_increase)
    # Patch version
    self.patch_version = case version_to_increase
                         when PATCH_VERSION
                           patch_version ||= 0
                           DmsfUploadHelper.increase_version patch_version
                         end
    # Minor version
    self.minor_version = case version_to_increase
                         when MINOR_VERSION
                           DmsfUploadHelper.increase_version minor_version
                         when MAJOR_VERSION
                           major_version.negative? ? -' '.ord : 0
                         else
                           minor_version
                         end
    # Major version
    self.major_version = case version_to_increase
                         when MAJOR_VERSION
                           DmsfUploadHelper.increase_version major_version
                         else
                           major_version
                         end
  end

  def copy_file_content(open_file)
    sha = Digest::SHA256.new
    File.open(disk_file(search_if_not_exists: false), 'wb') do |f|
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
    parts.size == 2 ? ((parts[0].to_i * 1_000) + parts[1].to_i) : 0
  end

  def formatted_name(member)
    format = if member&.dmsf_title_format.present?
               member.dmsf_title_format
             else
               Setting.plugin_redmine_dmsf['dmsf_global_title_format']
             end
    return name if format.blank?

    if name =~ /(.*)(\..*)$/
      filename = Regexp.last_match(1)
      ext = Regexp.last_match(2)
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
    self.digest = Digest::SHA256.file(path).hexdigest
  rescue StandardError => e
    Rails.logger.error e.message
    self.digest = 0
  end

  # Returns either MD5 or SHA256 depending on the way self.digest was computed
  def digest_type
    return nil if digest.blank?

    digest.size < 64 ? 'MD5' : 'SHA256'
  end

  def tooltip
    text = description.presence || +''
    if comment.present?
      text += ' / ' if text.present?
      text += comment
    end
    text
  end

  def workflow_tooltip
    tooltip = +''
    if dmsf_workflow
      case workflow
      when DmsfWorkflow::STATE_WAITING_FOR_APPROVAL, DmsfWorkflow::STATE_ASSIGNED
        assignments = dmsf_workflow.next_assignments(id)
        assignments&.each_with_index do |assignment, index|
          tooltip << ', ' if index.positive?
          tooltip << assignment.user.name
        end
      when DmsfWorkflow::STATE_APPROVED, DmsfWorkflow::STATE_REJECTED
        action = DmsfWorkflowStepAction.joins(:dmsf_workflow_step_assignment)
                                       .where(dmsf_workflow_step_assignments: { dmsf_file_revision_id: id })
                                       .order('dmsf_workflow_step_actions.created_at')
                                       .last
        tooltip << action.author.name if action
      end
    end
    tooltip
  end

  def protocol
    @protocol ||= PROTOCOLS[mime_type.downcase] if mime_type
    @protocol
  end

  def delete_source_revision
    DmsfFileRevision.where(source_dmsf_file_revision_id: id).find_each do |d|
      d.source_revision = source_revision
      d.save!
    end
    return unless Setting.plugin_redmine_dmsf['dmsf_really_delete_files']

    dependencies = DmsfFileRevision.where(disk_filename: disk_filename).all.size
    FileUtils.rm_f(disk_file) if dependencies <= 1
  end

  def copy_custom_field_values(values, source_revision = nil)
    # For a new revision we need to remember attachments' ids
    if source_revision
      ids = []
      source_revision.custom_field_values.each do |cv|
        ids << cv.value if cv.custom_field.format.is_a?(Redmine::FieldFormat::AttachmentFormat)
      end
    end
    # ActionParameters => Hash
    h = DmsfFileRevision.params_to_hash(values)
    # Super
    self.custom_field_values = h
    # For a new revision we need to duplicate attachments
    return unless source_revision

    i = 0
    custom_field_values.each do |cv|
      next unless cv.custom_field.format.is_a?(Redmine::FieldFormat::AttachmentFormat)

      if cv.value.blank? && h[cv.custom_field.id.to_s].present?
        a = Attachment.find_by(id: ids[i])
        copy = a.copy
        copy.save
        cv.value = copy.id
      end
      i += 1
    end
  end

  # Converts ActionParameters to an ordinary Hash
  def self.params_to_hash(params)
    result = {}
    return result if params.blank?

    h = params.permit!.to_hash
    h.each do |key, value|
      if value.is_a?(Hash)
        value = value.except('blank')
        _, v = value.first
        # We need a symbols here
        result[key] = if v&.key?('file') && v['file'].blank?
                        nil
                      else
                        v&.symbolize_keys
                      end
      else
        result[key] = value
      end
    end
    result
  end
end
