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

begin
  require 'xapian'
  $xapian_bindings_available = true
rescue LoadError
  Rails.logger.info "REDMAIN_XAPIAN ERROR: No Ruby bindings for Xapian installed !!. PLEASE install Xapian search engine interface for Ruby."
  $xapian_bindings_available = false
end

class DmsfFile < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :folder, :class_name => "DmsfFolder", :foreign_key => "dmsf_folder_id"
  has_many :locks, :class_name => "DmsfFileLock", :foreign_key => "dmsf_file_id", 
    :order => "updated_at DESC"
  belongs_to :deleted_by_user, :class_name => "User", :foreign_key => "deleted_by_user_id"
  
  validates_presence_of :name
  validates_format_of :name, :with => DmsfFolder.invalid_characters,
    :message => l(:error_contains_invalid_character)
  
  validate :validates_name_uniqueness 
  
  def validates_name_uniqueness
    existing_file = DmsfFile.find_file_by_name(self.project, self.folder, self.name)
    errors.add(:name, l("activerecord.errors.messages.taken")) unless
      existing_file.nil? || existing_file.id == self.id
  end
  
  acts_as_event :title => Proc.new {|o| "#{o.name}"},
                :description => Proc.new {|o| "#{o.last_revision.title} - #{o.last_revision.description}" },
                :url => Proc.new {|o| {:controller => "dmsf_files", :action => "show", :id => o, :download => ""}},
                :datetime => Proc.new {|o| o.updated_at },
                :author => Proc.new {|o| o.last_revision.user }
  
  #TODO: place into better place
  def self.storage_path
    storage_dir = Setting.plugin_redmine_dmsf["dmsf_storage_directory"].strip
    if !File.exists?(storage_dir)
      Dir.mkdir(storage_dir)
    end
    storage_dir
  end
  
  def self.project_root_files(project)
    find(:all, :conditions => 
      ["dmsf_folder_id is NULL and project_id = :project_id and deleted = :deleted",
        {:project_id => project.id, :deleted => false}], :order => "name ASC")
  end
  
  def self.find_file_by_name(project, folder, name)
    if folder.nil?
      find(:first, :conditions => 
        ["dmsf_folder_id is NULL and project_id = :project_id and name = :name and deleted = :deleted", 
          {:project_id => project.id, :name => name, :deleted => false}])
    else
      find(:first, :conditions => 
        ["dmsf_folder_id = :folder_id and project_id = :project_id and name = :name and deleted = :deleted", 
          {:project_id => project.id, :folder_id => folder.id, :name => name, :deleted => false}])
    end
  end

  def last_revision
    if @last_revision.nil?
      @last_revision = DmsfFileRevision.find(:first, :conditions => 
        ["dmsf_file_id = :file_id and deleted = :deleted", 
          {:file_id => self.id, :deleted => false}], 
          :order => "major_version DESC, minor_version DESC, updated_at DESC")
    end
    @last_revision
  end
  
  def reload
    @last_revision = nil
    super
  end

  def revisions(offset = nil, limit = nil)
    DmsfFileRevision.find(:all, :conditions => 
        ["dmsf_file_id = :file_id and deleted = :deleted", 
          {:file_id => self.id, :deleted => false}], 
          :order => "major_version DESC, minor_version DESC, updated_at DESC",
          :limit => limit, :offset => offset)
  end

  def delete
    return false if locked_for_user?
    self.deleted = true
    self.deleted_by_user = User.current
    save
  end
  
  def locked?
    self.locks.empty? ? false : self.locks[0].locked
  end
  
  def locked_for_user?
    self.locked? && self.locks[0].user != User.current
  end
  
  def lock
    l = DmsfFileLock.file_lock_state(self, true)
    self.reload
    return l
  end
  
  def unlock
    l = DmsfFileLock.file_lock_state(self, false)
    self.reload
    return l
  end
  
  def title
    self.last_revision.title
  end
  
  def version
    self.last_revision.version
  end
  
  def workflow
    self.last_revision.workflow
  end
  
  def dmsf_path
    path = self.folder.nil? ? [] : self.folder.dmsf_path
    path.push(self)
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
  
  def display_name
    #if self.name.length > 33
    #  extension = File.extname(self.name)
    #  return self.name[0, self.name.length - extension.length][0, 25] + "..." + extension
    #else 
      return self.name
    #end
  end
  
  # To fullfill searchable module expectations
  def self.search(tokens, projects=nil, options={})
    tokens = [] << tokens unless tokens.is_a?(Array)
    projects = [] << projects unless projects.nil? || projects.is_a?(Array)
    
    find_options = {:include => [:project,:revisions]}
    find_options[:order] = "dmsf_files.updated_at " + (options[:before] ? 'DESC' : 'ASC')
    
    limit_options = {}
    limit_options[:limit] = options[:limit] if options[:limit]
    if options[:offset]
      limit_options[:conditions] = "(dmsf_files.updated_at " + (options[:before] ? '<' : '>') + "'#{connection.quoted_date(options[:offset])}')"
    end
    
    columns = ["dmsf_files.name","dmsf_file_revisions.title", "dmsf_file_revisions.description"]
    columns = ["dmsf_file_revisions.title"] if options[:titles_only]
            
    token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ?)"}
    
    sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')
    find_options[:conditions] = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]
    
    project_conditions = []
    project_conditions << (Project.allowed_to_condition(User.current, :view_dmsf_files))
    project_conditions << "project_id IN (#{projects.collect(&:id).join(',')})" unless projects.nil?
    
    results = []
    results_count = 0
    
    with_scope(:find => {:conditions => [project_conditions.join(' AND ') + " AND #{DmsfFile.table_name}.deleted = :false", {:false => false}]}) do
      with_scope(:find => find_options) do
        results_count = count(:all)
        results = find(:all, limit_options)
      end
    end
    
    if !options[:titles_only] && $xapian_bindings_available
      database = nil
      begin
        database = Xapian::Database.new(Setting.plugin_redmine_dmsf["dmsf_index_database"].strip)
      rescue
        Rails.logger.warn "REDMAIN_XAPIAN ERROR: Xapian database is not properly set or initiated or is corrupted."
      end

      unless database.nil?
        enquire = Xapian::Enquire.new(database)
        
        queryString = tokens.join(' ')
        qp = Xapian::QueryParser.new()
        stemmer = Xapian::Stem.new(Setting.plugin_redmine_dmsf['dmsf_stemming_lang'].strip)
        qp.stemmer = stemmer
        qp.database = database
        
        case Setting.plugin_redmine_dmsf['dmsf_stemming_strategy'].strip
          when "STEM_NONE" then qp.stemming_strategy = Xapian::QueryParser::STEM_NONE
          when "STEM_SOME" then qp.stemming_strategy = Xapian::QueryParser::STEM_SOME
          when "STEM_ALL" then qp.stemming_strategy = Xapian::QueryParser::STEM_ALL
        end
      
        if options[:all_words]
          qp.default_op = Xapian::Query::OP_AND
        else  
          qp.default_op = Xapian::Query::OP_OR
        end
        
        query = qp.parse_query(queryString)
  
        enquire.query = query
        matchset = enquire.mset(0, 1000)
    
        unless matchset.nil?
          matchset.matches.each {|m|
            docdata = m.document.data{url}
            dochash = Hash[*docdata.scan(/(url|sample|modtime|type|size)=\/?([^\n\]]+)/).flatten]
            filename = dochash["url"]
            if !filename.nil?
              dmsf_attrs = filename.split("_")
              next unless results.select{|f| f.id.to_s == dmsf_attrs[1]}.empty?
              
              find_conditions =  DmsfFile.merge_conditions(limit_options[:conditions], :id => dmsf_attrs[1], :deleted => false )
              dmsf_file = DmsfFile.find(:first, :conditions =>  find_conditions  )
    
              if !dmsf_file.nil?
                if options[:offset]
                  if options[:before]
                    next if dmsf_file.updated_at < options[:offset]
                  else
                    next if dmsf_file.updated_at > options[:offset]
                  end
                end
              
                allowed = User.current.allowed_to?(:view_dmsf_files, dmsf_file.project)
                project_included = false
                project_included = true if projects.nil?
                if !project_included
                  projects.each {|x| 
                    project_included = true if x[:id] == dmsf_file.project.id
                  }
                end
  
                if (allowed && project_included)
                  results.push(dmsf_file)
                  results_count += 1
                end
              end
            end
          }
        end
      end    
    end
    
    [results, results_count]
  end
  
end