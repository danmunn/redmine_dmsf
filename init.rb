# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   V�t Jon� <vit.jonas@gmail.com>
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

require 'redmine'
require 'dmsf/init'

# strategise any rails specific startup information
#
# ToDo: Redmine < 2.0 is not yet supported, this check is redundant until support
# is implemented
if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  preparation_object = Dispatcher
else
  preparation_object = Rails.configuration
  RAILS_ROOT = Rails.root
end

Redmine::Plugin.register :redmine_dmsf do
  name "Redmine DMSF"
  author "Daniel Munn / Vit Jonas"
  description "Extended features for the Redmine document management system"
  requires_redmine :version_or_higher => "2.0.0"
  version "v1.5.0"

  settings :default => { 
                         :max_file_upload    => '0',
                         :max_file_download  => '0',
                         :max_email_filesize => '0',
                         :storage_directory  => File.join(Attachment.storage_path, 'dmsf').to_s,
                         :zip_encoding       => 'utf-8',
                         :indexing_database  => File.join(Attachment.storage_path, 'dmsf_index').to_s,
                         :stemming_lang      => 'english',
                         :stemming_strategy  => 'STEM_NONE',
                         :webdav             => {
                             :provider       => 'Webdav::None',
                             :configuration  => {},
                         }
                       },
           :partial => 'settings/dmsf_settings'
         
  # Roles & permissions
  project_module :dmsf do
    permission :approval_workflows, {:dmsf_workflows => [:new, :create, :destroy, :edit, :add_step, :remove_step, :reorder_steps, :update]}    
  end
            
  # Administration menu extension
  Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :workflow, {:controller => 'dmsf_workflows', :action => 'index'}, :caption => :label_dmsf_workflow_plural        
  end
  
  # Adds javascript and stylesheet tags for project tree view
  class DmsfViewListener < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      stylesheet_link_tag('dmsf', :plugin => :redmine_dmsf)
    end
  end
end

# Note:
#  Wizardry in effect; will load from the configuration
#  a module which will define a state for Webdav. The simple
#  intention here is to create an environment where someone
#  could potentially use the structure (module based on Webdav::Base
#  with a mount method) to extend how Dmsf provides Webdav
#  functionality, be that with 3rd party module (eg: redmine_dmsf)
#  or other.
#
#  Included are :
#  Webdav::None                   - No Webdav mounting (turned off)
#  Webdav::Dmsf::Standard         - Standard R/W webdav functionality
#  Webdav::Dmsf::Standard::Locked - Read-only Dmsf provided webdav
#
Rails.configuration.to_prepare do
  # Not really sure on the correct workaround here, as we need to dynamically 
  # mount based on a setting, we need DB - however it breaks migrations if the 
  # settings table does not exist - Settings is added early on in Redmine 
  # installation, so for now we'll check that the current version is not 0.
  return unless ActiveRecord::Migrator.current_version > 0
  #Webdav.mount_from_config
end