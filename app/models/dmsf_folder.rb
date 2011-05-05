class DmsfFolder < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :folder, :class_name => "DmsfFolder", :foreign_key => "dmsf_folder_id"
  has_many :subfolders, :class_name => "DmsfFolder", :foreign_key => "dmsf_folder_id", :order => "name ASC"
  has_many :files, :class_name => "DmsfFile", :foreign_key => "dmsf_folder_id", :order => "name ASC",
           :conditions => { :deleted => false }
  belongs_to :user
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:dmsf_folder_id, :project_id]
  
  def self.project_root_folders(project)
    find(:all, :conditions => 
        ["dmsf_folder_id is NULL and project_id = :project_id", {:project_id => project.id}], :order => "name ASC")
  end
  
  def self.create_from_params(project, parent_folder, params)
    new_folder = DmsfFolder.new(params)
    new_folder.project = project
    new_folder.folder = parent_folder
    new_folder.user = User.current
    new_folder.save
    new_folder
  end
  
  def dmsf_path
    folder = self
    path = []
    while !folder.nil?
      path.unshift(folder)
      folder = folder.folder
    end 
    path
  end
  
  def dmsf_path_str
    path = self.dmsf_path
    string_path = path.map { |element| element.name }
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
  
end

