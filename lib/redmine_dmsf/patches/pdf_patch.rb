# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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
#
# Redmine's PDF export patch to view DMS images

require 'redmine/export/pdf'

module RedmineDmsf
  module Patches
    # PDF
    module PdfPatch
      ##################################################################################################################
      # Overridden methods

      def get_image_filename(attrname)
        if attrname =~ %r{/dmsf/files/(\d+)/}
          file = DmsfFile.find_by(id: Regexp.last_match(1))
          file&.last_revision ? file.last_revision.disk_file : nil
        else
          super attrname
        end
      end
    end
  end
end

# Apply the patch
if Redmine::Plugin.installed?('easy_extensions')
  EasyPatchManager.register_patch_to_be_first 'Redmine::Export::PDF::ITCPDF', 'RedmineDmsf::Patches::PdfPatch',
                                              prepend: true, first: true
else
  Redmine::Export::PDF::ITCPDF.prepend RedmineDmsf::Patches::PdfPatch
end
