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

require_dependency 'project'

module RedmineDmsf
  module Patches
    module ProjectPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.class_eval do
          unloadable
          alias_method_chain :copy, :dmsf_copy
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def all_dmsf_custom_fields
          @all_dmsf_custom_fields ||= (DmsfFileRevisionCustomField.for_all).uniq.sort # + dmsf_file_revision_custom_fields).uniq.sort
        end
        
        def copy_with_dmsf_copy(project, options={})
          project = project.is_a?(Project) ? project : Project.find(project)
      
          to_be_copied = %w(wiki versions issue_categories issues members queries boards dmsf)
          to_be_copied = to_be_copied & options[:only].to_a unless options[:only].nil?
      
          Project.transaction do
            if save
              reload
              to_be_copied.each do |name|
                send "copy_#{name}", project
              end
              Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self)
              save
            end
          end
        end
      
        # Copies DMSF from +project+
        def copy_dmsf(project)          
          DmsfFolder.project_root_folders(project).each{|subfolder| subfolder.copy_to(self, nil)}
          DmsfFile.project_root_files(project).each{|file| file.copy_to(self, nil)}                   
        end 
      end
    end
  end
end

#Apply patch
Rails.configuration.to_prepare do
  unless Project.included_modules.include?(RedmineDmsf::Patches::ProjectPatch)
    Project.send(:include, RedmineDmsf::Patches::ProjectPatch)
  end
end
