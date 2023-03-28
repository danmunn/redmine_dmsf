# encoding: utf-8
# frozen_string_literal: true
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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

desc <<-END_DESC
Convert projects' Documents to DMSF folder/file structure.

Converted project must have Document module enabled

Available options:
  * project - id or identifier of a project (default to all projects)
  * dry_run - perform just a check without any conversion
  * issues - Convert also files attached to issues  

Example:
  rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"
  rake redmine:dmsf_convert_documents project=test dry_run=1 RAILS_ENV="production"
  rake redmine:dmsf_convert_documents project=test issues=1 RAILS_ENV="production"
END_DESC

class DmsfConvertDocuments

  def initialize
    @dry_run = ENV.fetch('dry_run', nil)
    @projects = []
    if ENV['project']
      p = Project.find(ENV['project'])
      @projects << p if p&.active?
    else
      @projects.concat(Project.active.to_a)
    end
    @issues = ENV.fetch('issues', nil)
  end

  def convert_projects
    if @projects.any?
      @projects.each do |project|
        $stdout.puts "Processing project: #{project.name}"
        convert_documents(project) if project.module_enabled?('documents')
        convert_issues(project) if (@issues && project.module_enabled?('issue_tracking'))
      end
    else
      $stderr.warn 'No active projects found.'
    end
  end

  def convert_issues(project)
    $stdout.puts 'Issues'
    unless Setting.plugin_redmine_dmsf['dmsf_act_as_attachable']
      $stderr.warn "'Act as attachable' must be checked in the plugin's settings"
      return
    end
    project.issues.each do |issue|
      if issue.attachments.any?
        $stdout.puts "Processing: #{issue}"
        project.enable_module!('dmsf') unless @dry_run
        # <issue.id> - <issue.subject> folder
        $stdout.puts "Creating #{issue.id} - #{DmsfFolder::get_valid_title(issue.subject)} folder"
        unless @dry_run
          folder = issue.system_folder(true, project.id)
        end
        files = []
        attachments = []
        issue.attachments.each do |attachment|
          @fail = false
          create_document_from_attachment(project, folder, attachment, files)
          attachments << attachment unless @fail
        end
        unless @dry_run
          attachments.each do |attachment|
            issue.init_journal User.anonymous
            issue.attachments.delete attachment
          end
        end
      end
    end
  end
  
  def convert_documents(project)
    @fail = false
    folders = []
    if project.documents.any?
      $stdout.puts 'Documents'
      project.enable_module!('dmsf') unless @dry_run
      project.documents.each do |document|
        $stdout.puts "Processing document: #{document.title}"
        folder = DmsfFolder.new
        folder.project = project
        attachment = document.attachments.reorder(created_on: :asc).first
        if attachment
          folder.user = attachment.author
        else
          folder.user = User.active.where(admin: true).first
        end
        folder.title = DmsfFolder.get_valid_title(document.title)
        i = 1
        suffix = ''
        while folders.index{ |f| f.title == (folder.title + suffix) }
          i+=1
          suffix = "_#{i}"
        end
        folder.title = folder.title + suffix
        folder.description = document.description
        if @dry_run
          $stdout.puts "Dry run folder: #{folder.title}"
          $stderr.warn(folder.errors.full_messages.to_sentence) if folder.invalid?
        else
          begin
            folder.save!
            $stdout.puts "Created folder: #{folder.title}"
          rescue => e
            $stderr.warn "Creating folder: #{folder.title} failed"
            $stderr.warn e.message
            @fail = true
            next
          end
        end
        folders << folder
        files = []
        @fail = false
        document.attachments.each do |attachment|
          create_document_from_attachment(project, folder, attachment, files)
        end
        document.destroy unless @dry_run || @fail
      end
    end
    unless @dry_run || @fail
      project.disable_module!('documents')
    end
  end

  private

  def create_document_from_attachment(project, folder, attachment, files)
    begin
      file = DmsfFile.new
      file.project_id = project.id
      file.dmsf_folder = folder
      file.name = attachment.filename
      i = 1
      suffix = ''
      while files.index{ |f| f.name == (DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name)) }
        i += 1
        suffix = "_#{i}"
      end
      # Need to save file first to generate id for it in case of creation.
      # File id is needed to properly generate revision disk filename
      file.name = DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name)
      unless File.exist?(attachment.diskfile)
        $stderr.warn "Creating file: #{attachment.filename} failed, attachment file #{attachment.diskfile} doesn't exist"
        @fail = true
        return
      end
      if @dry_run
        file.id = attachment.id # Just to have an ID there
        $stdout.puts "Dry run file: #{file.name}"
        $stderr.warn(file.errors.full_messages.to_sentence) if file.invalid?
      else
        file.save!
      end
      revision = DmsfFileRevision.new
      revision.dmsf_file = file
      revision.name = file.name
      revision.title = DmsfFileRevision.filename_to_title(attachment.filename)
      revision.description = attachment.description
      revision.user = attachment.author
      revision.created_at = attachment.created_on
      revision.updated_at = attachment.created_on
      revision.major_version = 0
      revision.minor_version = 1
      revision.comment = "Converted from #{folder.system ? 'Issues' : 'Documents'}"
      revision.mime_type = attachment.content_type
      revision.disk_filename = revision.new_storage_filename
      unless @dry_run
        FileUtils.cp attachment.diskfile, revision.disk_file(false)
        revision.size = File.size(revision.disk_file(false))
      end
      if @dry_run
        $stdout.puts "Dry run revision: #{revision.title}"
        $stderr.warn(revision.errors.full_messages.to_sentence) if revision.invalid?
      else
        revision.save!
      end
      files << file
      attachment.destroy unless @dry_run
      $stdout.puts "Created file: #{file.name}" unless @dry_run
    rescue => e
      $stderr.warn "Creating file: #{attachment.filename} failed"
      $stderr.warn e.message
      @fail = true
    end
  end

end

namespace :redmine do
  task :dmsf_convert_documents => :environment do
    convert = DmsfConvertDocuments.new
    convert.convert_projects
  end
end
