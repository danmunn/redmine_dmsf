require 'zip/zip'
require 'zip/zipfilesystem'

class DmsfZip
  
  attr_reader :file_count
  
  def initialize()
    @zip = Tempfile.new(["dmsf_zip",".zip"])
    @zip_file = Zip::ZipOutputStream.new(@zip.path)
    @file_count = 0
  end
  
  def finish
    @zip_file.close unless @zip_file.nil?
    @zip.path unless @zip.nil?
  end
  
  def close
    @zip_file.close unless @zip_file.nil?
    @zip.close unless @zip.nil?
  end
  
  def add_file(file)
    @zip_file.put_next_entry(file.dmsf_path_str)
    File.open(file.last_revision.disk_file, "rb") do |f| 
      buffer = ""
      while (buffer = f.read(8192))
        @zip_file.write(buffer)
      end
    end
    @file_count += 1
  end
  
  def add_folder(folder)
    @zip_file.put_next_entry(folder.dmsf_path_str + "/")
    folder.subfolders.each { |subfolder| self.add_folder(subfolder) }
    folder.files.each { |file| self.add_file(file) }
  end
  
end