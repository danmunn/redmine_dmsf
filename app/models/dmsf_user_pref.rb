class DmsfUserPref < ActiveRecord::Base
  unloadable
  belongs_to :project
  belongs_to :user
  
  validates_presence_of :project, :user
  validates_uniqueness_of :user_id, :scope => [:project_id]  
  
  def self.for(project, user)
    user_pref = find(:first, :conditions => 
      ["project_id = :project_id and user_id = :user_id", 
        {:project_id => project.id, :user_id => user.id}])
    user_pref = DmsfUserPref.new({:project_id => project.id, :user_id => user.id,
      :email_notify => nil}) if user_pref.nil?
    return user_pref
  end
  
end

