class DmsfFileLock < ActiveRecord::Base
  unloadable
  belongs_to :file, :class_name => "DmsfFile", :foreign_key => "dmsf_file_id"
  belongs_to :user  
end