require 'redmine_dmsf/patches' #plugin patches
require 'redmine_dmsf/webdav' #DAV4Rack implementation

module RedmineDmsf
end

#Add plugin's view folder into ActionMailer's paths to search
ActionMailer::Base.append_view_path(File.expand_path(File.dirname(__FILE__) + '/../app/views'))
