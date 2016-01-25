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

desc <<-END_DESC
Convert project documents to DMSF folder/file structure.

Converted project must have documents and may not have DMSF active!

Available options:
  * project - id or identifier of project (defaults to all projects)
  * dry - true or false (default false) to perform just check without any conversion
  * invalid - replace to perform document title invalid characters replacement for '-'

Example:
  rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"
END_DESC

class DmsfConvertDocuments
  
  def self.convert(options={})
    dry = options[:dry] ? options[:dry] == 'true' : false
    replace = options[:invalid] ? options[:invalid] == 'replace' : false
    
    projects = options[:project] ? [Project.find(options[:project])] : Project.active.to_a
    
    if projects
      prjs = projects.reject {|project| project.module_enabled?('dmsf') }
      diff = (projects - prjs)
      if diff.count > 0
        puts "Projects skipped due to already enabled module DMSF: #{diff.collect{|p| p.name }.join(' ,')}"
      end
      projects = prjs.reject {|project| !project.module_enabled?('documents') }
      diff = (prjs - projects)
      if diff.count > 0
        puts "Projects skipped due to not enabled module Documents: #{diff.collect{|p| p.name }.join(' ,')}"
      end
      
      projects.each do |project|
        puts "Processing project: #{project}"

        project.enabled_module_names = (project.enabled_module_names << 'dmsf').uniq unless dry
        project.save! unless dry

        fail = false
        folders = []
        project.documents.each do |document|
          puts "Processing document: #{document.title}"

          folder = DmsfFolder.new

          folder.project = project          
          folder.user = document.attachments.reorder("#{Attachment.table_name}.created_on ASC").first.try(:author)

          folder.title = document.title
          folder.title.gsub!(/[\/\\\?":<>]/, '-') if replace

          i = 1
          suffix = ''
          while folders.index{|f| f.title == (folder.title + suffix)}
            i+=1
            suffix = "_#{i}"
          end

          folder.title = folder.title + suffix
          folder.description = document.description

          if dry
            puts "Dry check folder: #{folder.title}"
            if folder.invalid?
              folder.errors.each {|e,msg| puts "#{e}: #{msg}"}
            end
          else
            begin
              folder.save!
              puts "Created folder: #{folder.title}"
            rescue Exception => e
              puts "Creating folder: #{folder.title} failed"
              puts e
              fail = true
              next
            end
          end

          folders << folder;

          files = []          
          document.attachments.each do |attachment|
            begin
              file = DmsfFile.new
              file.project = project
              file.folder = folder

              file.name = attachment.filename
              i = 1
              suffix = ''
              while files.index{|f| f.name == (DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name))}
                i+=1
                suffix = "_#{i}"
              end

              # Need to save file first to generate id for it in case of creation. 
              # File id is needed to properly generate revision disk filename
              file.name = DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name)

              unless File.exist?(attachment.diskfile)
                puts "Creating file: #{attachment.filename} failed, attachment file #{attachment.diskfile} doesn't exist"
                fail = true
                next
              end

              if dry
                file.id = attachment.id # Just to have an ID there
                puts "Dry check file: #{file.name}"
                if file.invalid?
                  file.errors.each {|e, msg| puts "#{e}: #{msg}"}
                end
              else
                file.save!
              end

              revision = DmsfFileRevision.new
              revision.file = file
              revision.name = file.name              
              revision.title = DmsfFileRevision.filename_to_title(attachment.filename)
              revision.description = attachment.description
              revision.user = attachment.author
              revision.created_at = attachment.created_on
              revision.updated_at = attachment.created_on
              revision.major_version = 0
              revision.minor_version = 1
              revision.comment = 'Converted from documents'
              revision.mime_type = attachment.content_type

              revision.disk_filename = revision.new_storage_filename              

              unless dry
                FileUtils.cp(attachment.diskfile, revision.disk_file)                
                revision.size = File.size(revision.disk_file)
              end              

              if dry
                puts "Dry check revision: #{revision.title}"
                if revision.invalid?
                  revision.errors.each {|e, msg| puts "#{e}: #{msg}"}
                end
              else
                revision.save!
              end

              files << file

              attachment.destroy unless dry

              puts "Created file: #{file.name}" unless dry
            rescue Exception => e
              puts "Creating file: #{attachment.filename} failed"
              puts e
              fail = true
            end
          end

          document.destroy unless dry || fail

        end
        project.enabled_module_names = project.enabled_module_names.reject {|mod| mod == 'documents'} unless dry || fail
        project.save! unless dry
      end      
    end
    
  end
end

namespace :redmine do
  task :dmsf_convert_documents => :environment do
    options = {}
    options[:project] = ENV['project'] if ENV['project']
    options[:dry] = ENV['dry'] if ENV['dry']
    options[:invalid] = ENV['invalid'] if ENV['invalid']

    DmsfConvertDocuments.convert(options)
  end
end
