require 'redmine_dmsf/patches/custom_fields_helper'
require 'redmine_dmsf/patches/acts_as_customizable'
require 'redmine_dmsf/patches/project_patch'
require 'redmine_dmsf/webdav'

module RedmineDmsf
end

#Add plugin's view folder into ActionMailer's paths to search
ActionMailer::Base.append_view_path(File.expand_path(File.dirname(__FILE__) + '/../app/views'))
