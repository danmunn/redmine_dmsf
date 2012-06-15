# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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
      end

      module ClassMethods
      end

      module InstanceMethods
        def all_dmsf_custom_fields
          @all_dmsf_custom_fields ||= (DmsfFileRevisionCustomField.for_all).uniq.sort # + dmsf_file_revision_custom_fields).uniq.sort
        end
      end
    end
  end
end

#Apply patch
Rails.configuration.to_prepare do
  unless Projects.included_modules.include?(RedmineDmsf::Patches::ProjectPatch)
    Project.send(:include, RedmineDmsf::Patches::ProjectPatch)
  end
end