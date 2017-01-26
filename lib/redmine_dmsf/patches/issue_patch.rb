# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
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

require_dependency 'issue'

module RedmineDmsf
  module Patches
    module IssuePatch

      def self.included(base)
        base.class_eval do
          unloadable
          has_many :dmsf_files, -> { where(dmsf_folder_id: nil, container_type: 'Issue').order(:name) },
            :class_name => 'DmsfFile', :foreign_key => 'container_id', :dependent => :destroy
        end
      end

    end
  end
end

# Apply patch
Rails.configuration.to_prepare do
  unless Issue.included_modules.include?(RedmineDmsf::Patches::IssuePatch)
    Issue.send(:include, RedmineDmsf::Patches::IssuePatch)
  end
end
