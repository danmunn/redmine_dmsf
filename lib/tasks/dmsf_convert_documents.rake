desc <<-END_DESC
Convert project documents to DMSF folder/file structure.

Converted project must have documents and may not have DMSF active!

Available options:
  * project  => id or identifier of project (defaults to all projects)

Example:
  rake redmine:dmsf_convert_documents project=test RAILS_ENV="production"
END_DESC
require File.expand_path(File.dirname(__FILE__) + "/../../../../../config/environment")

class DmsfConvertDocuments
  
  def self.convert(options={})
    projects = options[:project] ? [Project.find(options[:project])] : Project.find(:all)
    
    projects.reject! {|project| !project.enabled_modules.index{|mod| mod.name == "dmsf"}.nil? }
    projects.reject! {|project| project.enabled_modules.index{|mod| mod.name == "documents"}.nil? }
    
    unless projects.nil? || projects.empty?
      projects.each do |project|
        puts "Processing project: " + project.identifier
        
        project.enabled_module_names = (project.enabled_module_names << "dmsf").uniq
        project.save!

        folders = []
        project.documents.each do |document|
          folder = DmsfFolder.new
          
          folder.project = project
          folder.user = (a = document.attachments.find(:first, :order => "created_on ASC")) ? a.author : User.find(:first)
          
          folder.name = document.title
          
          i = 1
          suffix = ""
          while folders.index{|f| f.name == (folder.name + suffix)}
            i+=1
            suffix = "_#{i}"
          end
          
          folder.name = folder.name + suffix
          
          folder.description = document.description
          
          folder.save!
          folders << folder;
          
          puts "Created folder: " + folder.name
          
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
              
              file.name = DmsfFileRevision.remove_extension(file.name) + suffix + File.extname(file.name)
              
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
              
              revision.disk_filename = file.new_storage_filename
              attachment_file = File.open(attachment.diskfile, "rb")
              File.open(revision.disk_file, "wb") do |f| 
                while (buffer = attachment_file.read(8192))
                  f.write(buffer)
                end
              end
              attachment_file.close
              
              revision.size = File.size(revision.disk_file)
  
              file.save!
              revision.save!
  
              files << file

              attachment.destroy
              
              puts "Created file: " + file.name
            rescue Exception => e
              puts "Creating file: " + attachment.filename + " failed"
            end
          end
          
          document.destroy
          
        end
        project.enabled_module_names = project.enabled_module_names.reject {|mod| mod == "documents"}
        project.save!
      end
    end
    
  end
end

namespace :redmine do
  task :dmsf_convert_documents => :environment do
    options = {}
    options[:project] = ENV['project'] if ENV['project']

    DmsfConvertDocuments.convert(options)
  end
end
