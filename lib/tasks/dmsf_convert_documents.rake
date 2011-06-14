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

desc <<-END_DESC
Convert project documents to DMSF folder/file structure.

Converted project must have documents and may not have DMSF active!

Available options:
  * project  => id or identifier of project (defaults to all projects)
  * dry  => true or false (default false) to perform just check

Example:
  rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"
END_DESC
require File.expand_path(File.dirname(__FILE__) + "/../../../../../config/environment")

class DmsfConvertDocuments
  
  def self.convert(options={})
    dry = options[:dry] ? options[:dry] == "true" : false
    
    projects = options[:project] ? [Project.find(options[:project])] : Project.find(:all)
    
    projects.reject! {|project| !project.enabled_modules.index{|mod| mod.name == "dmsf"}.nil? }
    projects.reject! {|project| project.enabled_modules.index{|mod| mod.name == "documents"}.nil? }
    
    unless projects.nil? || projects.empty?
      projects.each do |project|
        puts "Processing project: " + project.identifier
        
        project.enabled_module_names = (project.enabled_module_names << "dmsf").uniq unless dry
        project.save! unless dry

        folders = []
        project.documents.each do |document|
          puts "Processing document: " + document.title
          
          folder = DmsfFolder.new
          
          folder.project = project
          folder.user = (a = document.attachments.find(:first, :order => "created_on ASC")) ? a.author : User.find(:first)
          
          folder.title = document.title
          
          i = 1
          suffix = ""
          while folders.index{|f| f.title == (folder.title + suffix)}
            i+=1
            suffix = "_#{i}"
          end
          
          folder.title = folder.title + suffix
          folder.description = document.description

          if dry
            puts "Dry check folder: " + folder.title
            if folder.invalid?
              folder.errors.each {|e| puts "#{e[0]}: #{e[1]}"}
            end
          else
            begin
              folder.save!
              puts "Created folder: " + folder.title
            rescue Exception => e
              puts "Creating folder: " + folder.title + " failed"
              puts e
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
              suffix = ""
              while files.index{|f| f.name == (DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name))}
                i+=1
                suffix = "_#{i}"
              end
              
              # Need to save file first to generate id for it in case of creation. 
              # File id is needed to properly generate revision disk filename
              file.name = DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name)
              
              if dry
                puts "Dry check file: " + file.name
                if file.invalid?
                  file.errors.each {|e| puts "#{e[0]}: #{e[1]}"}
                end
              else
                file.save!
              end
              
              revision = DmsfFileRevision.new
              revision.file = file
              revision.name = file.name
              revision.folder = file.folder
              revision.title = DmsfFileRevision.filename_to_title(attachment.filename)
              revision.description = attachment.description
              revision.user = attachment.author
              revision.created_at = attachment.created_on
              revision.updated_at = attachment.created_on
              revision.major_version = 0
              revision.minor_version = 1
              revision.comment = "Converted from documents"
              revision.mime_type = attachment.content_type
              
              revision.disk_filename = revision.new_storage_filename
              attachment_file = File.open(attachment.diskfile, "rb")
              
              unless dry
                File.open(revision.disk_file, "wb") do |f| 
                  while (buffer = attachment_file.read(8192))
                    f.write(buffer)
                  end
                end
                revision.size = File.size(revision.disk_file)
              end

              attachment_file.close
              
              if dry
                puts "Dry check revision: " + revision.title
                if revision.invalid?
                  revision.errors.each {|e| puts "#{e[0]}: #{e[1]}"}
                end
              else
                revision.save!
              end
  
              files << file

              attachment.destroy unless dry
              
              puts "Created file: " + file.name unless dry
            rescue Exception => e
              puts "Creating file: " + attachment.filename + " failed"
              puts e
            end
          end
          
          document.destroy unless dry
          
        end
        project.enabled_module_names = project.enabled_module_names.reject {|mod| mod == "documents"} unless dry
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

    DmsfConvertDocuments.convert(options)
  end
end
