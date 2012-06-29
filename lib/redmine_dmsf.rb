#Vendor
require 'redmine_dmsf/vendored_dav4rack'

# DMSF libraries
require 'redmine_dmsf/patches' #plugin patches
require 'redmine_dmsf/webdav' #DAV4Rack implementation


#Hooks
require 'redmine_dmsf/hooks/view_projects_form_hook'

module RedmineDmsf
end

#Add plugin's view folder into ActionMailer's paths to search
ActionMailer::Base.append_view_path(File.expand_path(File.dirname(__FILE__) + '/../app/views'))
