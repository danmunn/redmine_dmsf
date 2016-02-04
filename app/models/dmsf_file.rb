# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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
rescue LoadError
  Rails.logger.info 'REDMAIN_XAPIAN ERROR: No Ruby bindings for Xapian installed !!. PLEASE install Xapian search engine interface for Ruby.'
  $xapian_bindings_available = false
end

class DmsfFile < ActiveRecord::Base
  unloadable
  
  include RedmineDmsf::Lockable        

  belongs_to :project
  belongs_to :folder, :class_name => 'DmsfFolder', :foreign_key => 'dmsf_folder_id'
  belongs_to :deleted_by_user, :class_name => 'User', :foreign_key => 'deleted_by_user_id'
  
  has_many :revisions, -> { order("#{DmsfFileRevision.table_name}.major_version DESC, #{DmsfFileRevision.table_name}.minor_version DESC, #{DmsfFileRevision.table_name}.updated_at DESC") },
    :class_name => 'DmsfFileRevision', :foreign_key => 'dmsf_file_id',
    :dependent => :destroy
  has_many :locks, -> { where(entity_type: 0).order("#{DmsfLock.table_name}.updated_at DESC") },
    :class_name => 'DmsfLock', :foreign_key => 'entity_id', :dependent => :destroy
  has_many :referenced_links, -> { where target_type: DmsfFile.model_name.to_s},
    :class_name => 'DmsfLink', :foreign_key => 'target_id', :dependent => :destroy
  accepts_nested_attributes_for :revisions, :locks, :referenced_links, :project    
  
  scope :visible, lambda { |*args|
    where(deleted: false) 
  }
  scope :deleted, lambda { |*args|
    where(deleted: true)
  }  

  validates :name, :presence => true
  validates_format_of :name, :with => DmsfFolder.invalid_characters,
    :message => l(:error_contains_invalid_character)

  validate :validates_name_uniqueness

  def validates_name_uniqueness
    existing_file = DmsfFile.visible.find_file_by_name(self.project, self.folder, self.name)
    errors.add(:name, l('activerecord.errors.messages.taken')) unless
      existing_file.nil? || existing_file.id == self.id
  end   

  acts_as_event :title => Proc.new { |o| o.name },
                :description => Proc.new { |o|                  
                  desc = Redmine::Search.cache_store.fetch("DmsfFile-#{o.id}")                  
                  if desc
                    Redmine::Search.cache_store.delete("DmsfFile-#{o.id}")                      
                  else
                    desc = o.description
                    desc += ' / ' if o.description.present? && o.last_revision.comment.present?
                    desc += o.last_revision.comment if o.last_revision.comment.present?
                  end                 
                  desc
                },
                :url => Proc.new { |o| {:controller => 'dmsf_files', :action => 'show', :id => o} },
                :datetime => Proc.new { |o| o.updated_at },
                :author => Proc.new { |o| o.last_revision.user }
              
  acts_as_searchable :columns => ["#{table_name}.name", "#{DmsfFileRevision.table_name}.title", "#{DmsfFileRevision.table_name}.description", "#{DmsfFileRevision.table_name}.comment"],
    :project_key => 'project_id',
    :date_column => "#{table_name}.updated_at"    

  before_create :default_values
  def default_values
    @notifications = Setting.plugin_redmine_dmsf['dmsf_default_notifications']
    if @notifications == '1'
      self.notification = true
    else
      self.notification = nil
    end
  end

  @@storage_path = nil

  def self.storage_path
    unless @@storage_path.present?
      @@storage_path = Setting.plugin_redmine_dmsf['dmsf_storage_directory'].strip if Setting.plugin_redmine_dmsf['dmsf_storage_directory'].present?
      @@storage_path = Pathname(Redmine::Configuration['attachments_storage_path']).join('dmsf') if @@storage_path.blank? && Redmine::Configuration['attachments_storage_path'].present?
      @@storage_path = Rails.root.join('files/dmsf').to_s if @@storage_path.blank?
      Dir.mkdir(@@storage_path) unless File.exists?(@@storage_path)
    end
    @@storage_path
  end

  # Lets introduce a write for storage path, that way we can also
  # better interact from test-cases etc
  def self.storage_path=(obj)
    @@storage_path = obj
  end

  def self.find_file_by_name(project, folder, name)
    where(
      :project_id => project,
      :dmsf_folder_id => folder ? folder.id : nil,
      :name => name).visible.first
  end

  def last_revision
    unless @last_revision
      @last_revision = deleted ? self.revisions.first : self.revisions.visible.first
    end
    @last_revision
  end

  def set_last_revision(new_revision)
    @last_revision = new_revision
  end

  def delete(commit)
    if locked_for_user?
      Rails.logger.info l(:error_file_is_locked)
      errors[:base] << l(:error_file_is_locked)
      return false
    end
    begin
      # Revisions and links of a deleted file SHOULD be deleted too
      self.revisions.each { |r| r.delete(commit, true) }
      self.referenced_links.each { |l| l.delete(commit) }
      if commit
        self.destroy
      else
        self.deleted = true
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
    if self.dmsf_folder_id && (self.folder.nil? || self.folder.deleted)
      errors[:base] << l(:error_parent_folder)
      return false
    end
    self.revisions.each { |r| r.restore }
    self.referenced_links.each { |l| l.restore }
    self.deleted = false
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
    path = self.folder.nil? ? [] : self.folder.dmsf_path
    path.push(self)
    path
  end

  def dmsf_path_str
    self.dmsf_path.map { |element| element.title }.join('/')
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

  # Returns an array of projects that current user can copy file to
  def self.allowed_target_projects_on_copy
    projects = []
    if User.current.admin?
      projects = Project.visible.has_module('dmsf').all
    elsif User.current.logged?
      User.current.memberships.each {|m| projects << m.project if m.roles.detect {|r| r.allowed_to?(:file_manipulation)} && m.project.module_enabled?('dmsf')}
    end
    projects
  end

  def move_to(project, folder)
    if self.locked_for_user?
      errors[:base] << l(:error_file_is_locked)
      return false
    end

    # If the target project differs from the source project we must physically move the disk files
    if self.project != project
      self.revisions.all.each do |rev|
        if File.exist? rev.disk_file(self.project)
          FileUtils.mv rev.disk_file(self.project), rev.disk_file(project)
        end
      end
    end

    self.project = project
    self.folder = folder
    new_revision = self.last_revision.clone
    new_revision.file = self
    new_revision.comment = l(:comment_moved_from, :source => "#{self.project.identifier}:#{self.dmsf_path_str}")
    new_revision.custom_values = []

    self.last_revision.custom_values.each do |cv|
      new_revision.custom_values << CustomValue.new({:custom_field => cv.custom_field, :value => cv.value})
    end

    self.save && new_revision.save
  end

  def copy_to(project, folder)

    # If the target project differs from the source project we must physically move the disk files
    if self.project != project
      self.revisions.all.each do |rev|
        if File.exist? rev.disk_file(self.project)
          FileUtils.cp rev.disk_file(self.project), rev.disk_file(project)
        end
      end
    end

    file = DmsfFile.new
    file.folder = folder
    file.project = project
    file.name = self.name
    file.notification = Setting.plugin_redmine_dmsf['dmsf_default_notifications'].present?

    if file.save && self.last_revision
      new_revision = self.last_revision.clone
      new_revision.file = file
      new_revision.comment = l(:comment_copied_from, :source => "#{self.project.identifier}: #{self.dmsf_path_str}")

      new_revision.custom_values = []
      self.last_revision.custom_values.each do |cv|
        new_revision.custom_values << CustomValue.new({:custom_field => cv.custom_field, :value => cv.value})
      end

      file.delete(true) unless new_revision.save
    end

    return file
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
    project_conditions << "#{DmsfFile.table_name}.project_id IN (#{project_ids.join(',')})" if project_ids.present?

    results = []        
    
    scope = self.visible.joins(:project, :revisions)
    scope = scope.limit(options[:limit]) unless options[:limit].blank?    
    scope = scope.where(limit_options) unless limit_options.blank?
    scope = scope.where(project_conditions.join(' AND '))    
    results = scope.where(find_options).uniq.to_a

    if !options[:titles_only] && $xapian_bindings_available
      database = nil
      begin
        lang = Setting.plugin_redmine_dmsf['dmsf_stemming_lang'].strip
        databasepath = File.join(
          Setting.plugin_redmine_dmsf['dmsf_index_database'].strip, lang)
        database = Xapian::Database.new(databasepath)
      rescue Exception => e
        Rails.logger.warn 'REDMAIN_XAPIAN ERROR: Xapian database is not properly set or initiated or is corrupted.'
        Rails.logger.warn e.message
      end

      if database
        enquire = Xapian::Enquire.new(database)

        query_string = tokens.join(' ')
        qp = Xapian::QueryParser.new()
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

        query = qp.parse_query(query_string)

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

              if dmsf_file
                if user.allowed_to?(:view_dmsf_files, dmsf_file.project) && 
                    (project_ids.blank? || (project_ids.include?(dmsf_file.project.id)))                                    
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
    if self.name.length > 50
      return "#{self.name[0, 25]}...#{self.name[-25, 25]}"
    end
    self.name
  end
  
  def image?
    self.last_revision && !!(self.last_revision.disk_filename =~ /\.(bmp|gif|jpg|jpe|jpeg|png|svg)$/i)
  end
  
  def preview(limit)
    result = 'No preview available'
    if (self.last_revision.disk_filename =~ /\.(txt|ini|diff|c|cpp|php|csv|rb|h|erb|html|css|py)$/i)
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
 
end
