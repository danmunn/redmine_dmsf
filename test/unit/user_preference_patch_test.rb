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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

# User preference tests
class UserPreferencePatchTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_user_preference_has_dmsf_attachments_upload_choice
    assert @jsmith.pref.respond_to?(:dmsf_attachments_upload_choice)
  end

  def test_user_preference_has_default_dmsf_query
    assert @jsmith.pref.respond_to?(:default_dmsf_query)
  end

  def test_user_preference_has_receive_download_notification
    assert @jsmith.pref.respond_to?(:receive_download_notification)
  end
end
