# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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

begin
  require 'xapian'
  $xapian_bindings_available = true
rescue LoadError => e
  Rails.logger.warn %{No Xapian search engine interface for Ruby installed => Full-text search won't be available.
                      Install a ruby-xapian package or an alternative Xapian binding (https://xapian.org).}
  Rails.logger.warn e.message
  $xapian_bindings_available = false
end

class DmsfFile < ActiveRecord::Base

  include RedmineDmsf::Lockable

  belongs_to :project
  belongs_to :dmsf_folder
  belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'

  has_many :dmsf_file_revisions, -> { order("#{DmsfFileRevision.table_name}.id DESC") },
    :dependent => :destroy
  has_many :locks, -> { where(entity_type: 0).order("#{DmsfLock.table_name}.updated_at DESC") },
    :class_name => 'DmsfLock', :foreign_key => 'entity_id', :dependent => :destroy
  has_many :referenced_links, -> { where target_type: DmsfFile.model_name.to_s},
    :class_name => 'DmsfLink', :foreign_key => 'target_id', :dependent => :destroy
  has_many :dmsf_public_urls, :dependent => :destroy

  STATUS_DELETED = 1
  STATUS_ACTIVE = 0

  scope :visible, -> { where(:deleted => STATUS_ACTIVE) }
  scope :deleted, -> { where(:deleted => STATUS_DELETED) }

  validates :name, :presence => true
  validates_format_of :name, :with => /\A[^#{DmsfFolder::INVALID_CHARACTERS}]*\z/,
    :message => l(:error_contains_invalid_character)
  validates :project, :presence => true
  validate :validates_name_uniqueness

  def validates_name_uniqueness
    existing_file = DmsfFile.select(:id).findn_file_by_name(self.project_id, self.dmsf_folder, self.name)
    errors.add(:name, l('activerecord.errors.messages.taken')) unless (existing_file.nil? || existing_file.id == self.id)
  end

  acts_as_event :title => Proc.new { |o| o.name },
                :description => Proc.new { |o|
                  desc = Redmine::Search.cache_store.fetch("DmsfFile-#{o.id}")
                  if desc
                    Redmine::Search.cache_store.delete("DmsfFile-#{o.id}")
                  else
                    # Set desc to an empty string if o.description is nil
                    desc = o.description.nil? ? '' : o.description
                    desc += ' / ' if o.description.present? && o.last_revision.comment.present?
                    desc += o.last_revision.comment if o.last_revision.comment.present?
                  end
                  desc
                },
                :url => Proc.new { |o| {:controller => 'dmsf_files', :action => 'view', :id => o} },
                :datetime => Proc.new { |o| o.updated_at },
                :author => Proc.new { |o| o.last_revision.user }

  acts_as_searchable :columns => ["#{table_name}.name", "#{DmsfFileRevision.table_name}.title", "#{DmsfFileRevision.table_name}.description", "#{DmsfFileRevision.table_name}.comment"],
    :project_key => 'project_id',
    :date_column => "#{table_name}.updated_at"

  before_create :default_values

  def default_values
    if (Setting.plugin_redmine_dmsf['dmsf_default_notifications'] == '1') && (!self.dmsf_folder || !self.dmsf_folder.system)
      self.notification = true
    end
  end

  def initialize
    @project = nil
    super
  end

  def self.storage_path
    path = Setting.plugin_redmine_dmsf['dmsf_storage_directory'].try(:strip)
    if path.blank?
      path = Pathname.new('files').join('dmsf').to_s
    else
      pn = Pathname.new(path)
      return pn if pn.absolute?
    end
    Rails.root.join(path)
  end

  def self.find_file_by_name(project, folder, name)
    self.findn_file_by_name(project.id, folder, name)
  end

  def self.findn_file_by_name(project_id, folder, name)
    where(
      :project_id => project_id,
      :dmsf_folder_id => folder ? folder.id : nil,
      :name => name).visible.first
  end

  def last_revision
    unless defined?(@last_revision)
      @last_revision = self.deleted? ? self.dmsf_file_revisions.first : self.dmsf_file_revisions.visible.first
    end
    @last_revision
  end

  def set_last_revision(new_revision)
    @last_revision = new_revision
  end

  def deleted?
    self.deleted == STATUS_DELETED
  end

  def delete(commit)
    if locked_for_user? && (!User.current.allowed_to?(:force_file_unlock, self.project))
      Rails.logger.info l(:error_file_is_locked)
      if self.lock.reverse[0].user
        errors[:base] << l(:title_locked_by_user, :user => self.lock.reverse[0].user)
      else
        errors[:base] << l(:error_file_is_locked)
      end
      return false
    end
    begin
      # Revisions and links of a deleted file SHOULD be deleted too
      self.dmsf_file_revisions.each { |r| r.delete(commit, true) }
      if commit
        if self.container.is_a?(Issue)
          self.container.dmsf_file_removed(self)
        end
        self.destroy
      else
        self.deleted = STATUS_DELETED
        self.deleted_by_user = User.current
        save
      end
    rescue Exception => e
      Rails.logger.error e.message
      errors[:base] << e.message
      return false
    end
  end

  def restore
    if self.dmsf_folder_id && (self.dmsf_folder.nil? || self.dmsf_folder.deleted?)
      errors[:base] << l(:error_parent_folder)
      return false
    end
    self.dmsf_file_revisions.each { |r| r.restore }
    self.deleted = STATUS_ACTIVE
    self.deleted_by_user = nil
    save
  end

  def title
    self.last_revision ? self.last_revision.title : self.name
  end

  def description
    self.last_revision ? self.last_revision.description : ''
  end

  def version
    self.last_revision ? self.last_revision.version : '0'
  end

  def workflow
    self.last_revision ? self.last_revision.workflow : nil
  end

  def size
    self.last_revision ? self.last_revision.size : 0
  end

  def dmsf_path
    path = self.dmsf_folder ? self.dmsf_folder.dmsf_path : []
    path.push(self)
    path
  end

  def dmsf_path_str
    self.dmsf_path.map { |element| element.title }.join('/')
  end

  def notify?
    return true if self.notification
    return true if self.dmsf_folder && self.dmsf_folder.notify?
    return true if !self.dmsf_folder && self.project.dmsf_notification
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

  # Returns an array of projects that current user can copy file to
  def self.allowed_target_projects_on_copy
    projects = []
    if User.current.admin?
      projects = Project.visible.has_module('dmsf').all
    elsif User.current.logged?
      User.current.memberships.each do |m|
        projects << m.project if m.project.module_enabled?('dmsf') &&
          m.roles.detect { |r| r.allowed_to?(:file_manipulation) }
      end
    end
    projects
  end

  def move_to(project, folder)
    if self.locked_for_user?
      errors[:base] << l(:error_file_is_locked)
      return false
    end
    source = "#{self.project.identifier}:#{self.dmsf_path_str}"
    self.project_id = project.id
    self.dmsf_folder = folder
    new_revision = self.last_revision.clone
    new_revision.dmsf_file = self
    new_revision.comment = l(:comment_moved_from, :source => source)
    new_revision.custom_values = []
    self.last_revision.custom_values.each do |cv|
      new_revision.custom_values << CustomValue.new({:custom_field => cv.custom_field, :value => cv.value})
    end
    self.set_last_revision(new_revision)
    self.save && new_revision.save
  end

  def copy_to(project, folder = nil)
    copy_to_filename(project, folder, self.name)
  end
  
  def copy_to_filename(project, folder, filename)
    file = DmsfFile.new
    file.dmsf_folder_id = folder.id if folder
    file.project_id = project.id
    file.name = filename
    file.notification = Setting.plugin_redmine_dmsf['dmsf_default_notifications'].present?
    if file.save && self.last_revision
      new_revision = self.last_revision.clone
      new_revision.dmsf_file = file
      new_revision.disk_filename = new_revision.new_storage_filename
      # Assign the same workflow if it's a global one or we are in the same project
      new_revision.workflow = nil
      new_revision.dmsf_workflow_id = nil
      new_revision.dmsf_workflow_assigned_by = nil
      new_revision.dmsf_workflow_assigned_at = nil
      new_revision.dmsf_workflow_started_by = nil
      new_revision.dmsf_workflow_started_at = nil
      wf = last_revision.dmsf_workflow
      if wf && (wf.project.nil? || (wf.project.id == project.id))
        new_revision.set_workflow(wf.id, nil)
        new_revision.assign_workflow(wf.id)
      end
      if File.exist? self.last_revision.disk_file
        FileUtils.cp self.last_revision.disk_file, new_revision.disk_file(false)
      end
      new_revision.comment = l(:comment_copied_from, :source => "#{project.identifier}: #{self.dmsf_path_str}")
      new_revision.custom_values = []
      self.last_revision.custom_values.each do |cv|
        v = CustomValue.new
        v.custom_field = cv.custom_field
        v.value = cv.value
        new_revision.custom_values << v
      end
      unless new_revision.save
        Rails.logger.error new_revision.errors.full_messages.to_sentence
        file.delete(true)
        file = nil
      else
        file.set_last_revision new_revision
      end
    else
      Rails.logger.error file.errors.full_messages.to_sentence
      file.delete(true)
      file = nil
    end
    file
  end

  # To fulfill searchable module expectations
  def self.search(tokens, projects = nil, options = {}, user = User.current)
    tokens = [] << tokens unless tokens.is_a?(Array)
    projects = [] << projects if projects.is_a?(Project)
    project_ids = projects.collect(&:id) if projects

    if options[:offset]
       limit_options = ["dmsf_files.updated_at #{options[:before] ? '<' : '>'} ?", options[:offset]]
    end

    if options[:titles_only]
      columns = [searchable_options[:columns][1]]
    else
      columns = searchable_options[:columns]
    end

    token_clauses = columns.collect{ |column| "(LOWER(#{column}) LIKE ?)" }

    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')
    find_options = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]

    project_conditions = []
    project_conditions << Project.allowed_to_condition(user, :view_dmsf_files)
    project_conditions << "#{Project.table_name}.id IN (#{project_ids.join(',')})" if project_ids.present?

    scope = self.visible.joins('JOIN dmsf_file_revisions ON dmsf_file_revisions.dmsf_file_id = dmsf_files.id').joins(:project)
    scope = scope.limit(options[:limit]) unless options[:limit].blank?
    scope = scope.where(limit_options) unless limit_options.blank?
    scope = scope.where(project_conditions.join(' AND '))
    results = scope.where(find_options).uniq.to_a
    results.delete_if{ |x| !DmsfFolder.permissions?(x.dmsf_folder) }

    if !options[:titles_only] && $xapian_bindings_available
      database = nil
      begin
        lang = Setting.plugin_redmine_dmsf['dmsf_stemming_lang'].strip
        databasepath = File.join(
          Setting.plugin_redmine_dmsf['dmsf_index_database'].strip, lang)
        database = Xapian::Database.new(databasepath)
      rescue Exception => e
        Rails.logger.error "REDMINE_XAPIAN ERROR: Xapian database is not properly set, initiated or it's corrupted."
        Rails.logger.error e.message
      end

      if database
        enquire = Xapian::Enquire.new(database)

        # Combine the rest of the command line arguments with spaces between
        # them, so that simple queries don't have to be quoted at the shell
        # level.
        query_string = tokens.map{ |x| !(x[-1,1].eql?'*')? x+'*': x }.join(' ')
        qp = Xapian::QueryParser.new
        stemmer = Xapian::Stem.new(lang)
        qp.stemmer = stemmer
        qp.database = database

        case Setting.plugin_redmine_dmsf['dmsf_stemming_strategy'].strip
          when 'STEM_NONE'
            qp.stemming_strategy = Xapian::QueryParser::STEM_NONE
          when 'STEM_SOME'
            qp.stemming_strategy = Xapian::QueryParser::STEM_SOME
          when 'STEM_ALL'
            qp.stemming_strategy = Xapian::QueryParser::STEM_ALL
        end

        if options[:all_words]
          qp.default_op = Xapian::Query::OP_AND
        else
          qp.default_op = Xapian::Query::OP_OR
        end

        flags = Xapian::QueryParser::FLAG_WILDCARD
        flags |= Xapian::QueryParser::FLAG_CJK_NGRAM if Setting.plugin_redmine_dmsf['enable_cjk_ngrams']

        query = qp.parse_query(query_string, flags)

        enquire.query = query
        matchset = enquire.mset(0, 1000)

        if matchset
          matchset.matches.each { |m|
            docdata = m.document.data{url}
            dochash = Hash[*docdata.scan(/(url|sample|modtime|author|type|size)=\/?([^\n\]]+)/).flatten]
            filename = dochash['url']
            if filename
              dmsf_attrs = filename.scan(/^([^\/]+\/[^_]+)_([\d]+)_(.*)$/)
              id_attribute = 0
              id_attribute = dmsf_attrs[0][1] if dmsf_attrs.length > 0
              next if dmsf_attrs.length == 0 || id_attribute == 0
              next unless results.select{|f| f.id.to_s == id_attribute}.empty?

              dmsf_file = DmsfFile.visible.where(limit_options).where(:id => id_attribute).first

              if dmsf_file && DmsfFolder.permissions?(dmsf_file.dmsf_folder)
                if user.allowed_to?(:view_dmsf_files, dmsf_file.project) &&
                    (project_ids.blank? || (project_ids.include?(dmsf_file.project_id)))
                    Redmine::Search.cache_store.write("DmsfFile-#{dmsf_file.id}",
                      dochash['sample'].force_encoding('UTF-8')) if dochash['sample']
                  break if(!options[:limit].blank? && results.count >= options[:limit])
                  results << dmsf_file
                end
              end
            end
          }
        end
      end
    end

    [results, results.count]
  end

  def self.search_result_ranks_and_ids(tokens, user = User.current, projects = nil, options = {})
    r = self.search(tokens, projects, options, user)[0]
    r.map{ |f| [f.updated_at.to_i, f.id]}
  end

  def display_name
    member = Member.where(:user_id => User.current.id, :project_id => self.project_id).first
    if member && !member.dmsf_title_format.nil? && !member.dmsf_title_format.empty?
      title_format = member.dmsf_title_format
    else
      title_format = Setting.plugin_redmine_dmsf['dmsf_global_title_format']
    end
    fname = formatted_name(title_format)
    if fname.length > 50
      return "#{fname[0, 25]}...#{fname[-25, 25]}"
    end
    fname
  end

  def text?
    self.last_revision && Redmine::MimeType.is_type?('text', self.last_revision.disk_filename)
  end

  def image?
    self.last_revision && Redmine::MimeType.is_type?('image', self.last_revision.disk_filename)
  end

  def pdf?
    self.last_revision && (Redmine::MimeType.of(self.last_revision.disk_filename) == 'application/pdf')
  end


  def disposition
    (self.image? || self.pdf?) ? 'inline' : 'attachment'
  end

  def preview(limit)
    result = 'No preview available'
    if self.text?
      begin
        f = File.new(self.last_revision.disk_file)
        f.each_line do |line|
          case f.lineno
            when 1
              result = line
            when limit.to_i + 1
              break
            else
              result << line
          end
        end
      rescue Exception => e
        result = e.message
      end
    end
    result
  end

  def formatted_name(format)
    if self.last_revision
      self.last_revision.formatted_name(format)
    else
      self.name
    end
  end

  def owner?(user)
    last_revision && (last_revision.user == user)
  end

  def involved?(user)
    dmsf_file_revisions.each do |file_revision|
      return true if file_revision.user == user
    end
    false
  end

  def assigned?(user)
    if last_revision && last_revision.dmsf_workflow
      last_revision.dmsf_workflow.next_assignments(last_revision.id).each do |assignment|
        return true if assignment.user == user
      end
    end
    false
  end

  def custom_value(custom_field)
    self.last_revision.custom_field_values.each do |cv|
      if cv.custom_field == custom_field
        if cv.value.is_a? Array
          return cv.value.reject{ |x| x.empty? }.join(',')
        else
          return cv.value
        end
      end
    end
    nil
  end

  def extension
    File.extname(last_revision.disk_filename).strip.downcase[1..-1] if last_revision
  end

  include ActionView::Helpers::NumberHelper
  include Rails.application.routes.url_helpers

  def to_csv(columns, level)
    csv = []
    # Project
    csv << self.project.name if columns.include?(l(:field_project))
    # Id
    csv << self.id if columns.include?('id')
    # Title
    csv << self.title.insert(0, '  ' * level) if columns.include?('title')
    # Extension
    csv << self.extension if columns.include?('extension')
    # Size
    csv << number_to_human_size(self.last_revision.size) if columns.include?('size')
    # Modified
    if columns.include?('modified')
      if self.last_revision
        csv << format_time(self.last_revision.updated_at)
      else
        csv << ''
      end
    end
    # Version
    if columns.include?('version')
      if self.last_revision
        csv << self.last_revision.version
      else
        csv << ''
      end
    end
    # Workflow
    if columns.include?('workflow')
      if self.last_revision
        csv << self.last_revision.workflow_str(false)
      else
        csv << ''
      end
    end
    # Author
    if columns.include?('author')
      if self.last_revision && self.last_revision.user
        csv << self.last_revision.user.name
      else
        csv << ''
      end
    end
    # Last approver
    if columns.include?(l(:label_last_approver))
      if self.last_revision && self.last_revision.dmsf_workflow
        csv << self.last_revision.workflow_tooltip
      else
        csv << ''
      end
    end
    # Url
    if columns.include?(l(:label_document_url))
      default_url_options[:host] = Setting.host_name
      csv << url_for(:controller => :dmsf_files, :action => 'view', :id => self.id)
    end
    # Revision
    if columns.include?(l(:label_last_revision_id))
      if self.last_revision
        csv << self.last_revision.id
      else
        csv << ''
      end
    end
    # Custom fields
    cfs = CustomField.where(:type => 'DmsfFileRevisionCustomField').order(:position)
    cfs.each do |c|
      csv << self.custom_value(c) if columns.include?(c.name)
    end
    csv
  end

  def thumbnail(options={})
    if image?
      size = options[:size].to_i
      if size > 0
        # Limit the number of thumbnails per image
        size = (size / 50) * 50
        # Maximum thumbnail size
        size = 800 if size > 800
      else
        size = Setting.thumbnails_size.to_i
      end
      size = 100 unless size > 0
      target = File.join(Attachment.thumbnails_storage_path, "#{self.id}_#{self.last_revision.digest}_#{size}.thumb")

      begin
        Redmine::Thumbnail.generate(self.last_revision.disk_file.to_s, target, size)
      rescue => e
        Rails.logger.error "An error occured while generating thumbnail for #{self.last_revision.disk_file} to #{target}\nException was: #{e.message}"
        return nil
      end
    end
  end

  def get_locked_title
    if self.locked_for_user?
      if self.lock.reverse[0].user
        return l(:title_locked_by_user, :user => self.lock.reverse[0].user)
      else
        return l(:notice_account_unknown_email)
      end
    end
    l(:title_unlock_file)
  end

  def container
    unless @container
      if self.dmsf_folder && self.dmsf_folder.system
        @container = Issue.where(:id => self.dmsf_folder.title.to_i).first
      end
    end
    @container
  end

end
