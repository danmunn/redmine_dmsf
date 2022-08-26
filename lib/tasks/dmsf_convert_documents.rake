# encoding: utf-8
# frozen_string_literal: true
# 
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-22 Karel Pičman <karel.picman@kontron.com>
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

Example:
  rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"
  rake redmine:dmsf_convert_documents project=test dry_run=1 RAILS_ENV="production"
END_DESC

class DmsfConvertDocuments
  
  def self.convert(options={})
    projects = []
    if options[:project]
      p = Project.find(options[:project])
      projects << p if p&.module_enabled?('documents')
    else
      projects = Project.active.has_module('documents').to_a
    end
    if projects.any?
      projects.each do |project|
        STDOUT.puts "Processing project: #{project.name}"
        unless options[:dry_run]
          project.enable_module! 'dmsf'
          #project.save!
        end
        fail = false
        folders = []
        project.documents.each do |document|
          STDOUT.puts "Processing document: #{document.title}"
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
          while folders.index{|f| f.title == (folder.title + suffix)}
            i+=1
            suffix = "_#{i}"
          end
          folder.title = folder.title + suffix
          folder.description = document.description
          if options[:dry_run]
            STDOUT.puts "Dry run folder: #{folder.title}"
            STDERR.puts(folder.errors.full_messages.to_sentence) if folder.invalid?
          else
            begin
              folder.save!
              STDOUT.puts "Created folder: #{folder.title}"
            rescue => e
              STDERR.puts "Creating folder: #{folder.title} failed"
              STDERR.puts e.message
              fail = true
              next
            end
          end
          folders << folder
          files = []          
          document.attachments.each do |attachment|
            begin
              file = DmsfFile.new
              file.project_id = project.id
              file.dmsf_folder = folder
              file.name = attachment.filename
              i = 1
              suffix = ''
              while files.index{|f| f.name == (DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name))}
                i += 1
                suffix = "_#{i}"
              end
              # Need to save file first to generate id for it in case of creation. 
              # File id is needed to properly generate revision disk filename
              file.name = DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name)
              unless File.exist?(attachment.diskfile)
                STDERR.puts "Creating file: #{attachment.filename} failed, attachment file #{attachment.diskfile} doesn't exist"
                fail = true
                next
              end
              if options[:dry_run]
                file.id = attachment.id # Just to have an ID there
                STDOUT.puts "Dry run file: #{file.name}"
                STDERR.puts(file.errors.full_messages.to_sentence) if file.invalid?
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
              revision.comment = 'Converted from Documents'
              revision.mime_type = attachment.content_type
              revision.disk_filename = revision.new_storage_filename
              unless options[:dry_run]
                FileUtils.cp attachment.diskfile, revision.disk_file(false)
                revision.size = File.size(revision.disk_file(false))
              end
              if options[:dry_run]
                STDOUT.puts "Dry run revision: #{revision.title}"
                STDERR.puts(revision.errors.full_messages.to_sentence) if revision.invalid?
              else
                revision.save!
              end
              files << file
              attachment.destroy unless options[:dry_run]
              STDOUT.puts "Created file: #{file.name}" unless options[:dry_run]
            rescue => e
              STDERR.puts "Creating file: #{attachment.filename} failed"
              STDERR.puts e.message
              fail = true
            end
          end
          document.destroy unless options[:dry_run] || fail
        end
        unless options[:dry_run] || fail
          project.disable_module!('documents')
        end
      end
    else
      STDERR.puts 'No project(s) with Documents module enabled found.'
    end
    
  end
end

namespace :redmine do
  task :dmsf_convert_documents => :environment do
    options = {}
    options[:project] = ENV['project']
    options[:dry_run] = ENV['dry_run']
    options[:invalid] = ENV['invalid']
    DmsfConvertDocuments.convert options
  end
end
