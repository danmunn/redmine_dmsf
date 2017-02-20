# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Patches
    module ProjectPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :copy, :dmsf

          has_many :dmsf_files, -> { where(dmsf_folder_id: nil, container_type: 'Project').order(:name) },
            :class_name => 'DmsfFile', :foreign_key => 'container_id', :dependent => :destroy
          has_many :dmsf_folders, -> { where(dmsf_folder_id: nil).order(:title) },
            :class_name => 'DmsfFolder', :foreign_key => 'project_id',
            :dependent => :destroy
          has_many :dmsf_workflows, :dependent => :destroy
          has_many :folder_links, -> { where dmsf_folder_id: nil, target_type: 'DmsfFolder' },
            :class_name => 'DmsfLink', :foreign_key => 'project_id', :dependent => :destroy
          has_many :file_links, -> { where dmsf_folder_id: nil, target_type: 'DmsfFile' },
            :class_name => 'DmsfLink', :foreign_key => 'project_id', :dependent => :destroy
          has_many :url_links, -> { where dmsf_folder_id: nil, target_type: 'DmsfUrl' },
            :class_name => 'DmsfLink', :foreign_key => 'project_id', :dependent => :destroy
          has_many :dmsf_links, -> { where dmsf_folder_id: nil },
            :class_name => 'DmsfLink', :foreign_key => 'project_id', :dependent => :destroy

          before_save :set_default_dmsf_notification
        end
      end

      module InstanceMethods

        def set_default_dmsf_notification
          if self.new_record?
            if !self.dmsf_notification && (Setting.plugin_redmine_dmsf['dmsf_default_notifications'] == '1')
              self.dmsf_notification = true
            end
          end
        end

        def dmsf_count
          file_count = self.dmsf_files.visible.count + self.file_links.visible.count
          folder_count = self.dmsf_folders.visible.count + self.folder_links.visible.count
          self.dmsf_folders.visible.each do |f|
            file_count += f.deep_file_count
            folder_count += f.deep_folder_count
          end
          { :files => file_count, :folders => folder_count }
        end

        def copy_with_dmsf(project, options={})
          copy_without_dmsf(project, options)

          project = project.is_a?(Project) ? project : Project.find(project)

          to_be_copied = %w(dmsf approval_workflows)
          to_be_copied = to_be_copied & Array.wrap(options[:only]) unless options[:only].nil?

          if save
            to_be_copied.each do |name|
              send "copy_#{name}", project
            end
            save
          end

        end

        # Simple yet effective approach to copying things
        def copy_dmsf(project)
          project.dmsf_folders.visible.each do |f|
            f.copy_to(self, nil)
          end
          project.dmsf_files.visible.each do |f|
            f.copy_to(self, nil)
          end
          project.folder_links.visible.each do |l|
            l.copy_to(self, nil)
          end
          project.file_links.visible.each do |l|
            l.copy_to(self, nil)
          end
          project.url_links.visible.each do |l|
            l.copy_to(self, nil)
          end
        end

        def copy_approval_workflows(project)
          project.dmsf_workflows.each do |wf|
            wf.copy_to self
          end
        end
      end

    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless Project.included_modules.include?(RedmineDmsf::Patches::ProjectPatch)
    Project.send(:include, RedmineDmsf::Patches::ProjectPatch)
  end
end
