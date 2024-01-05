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

require File.expand_path('../../test_helper', __FILE__)

# Upload tests
class DmsfUploadTest < RedmineDmsf::Test::UnitTest
  fixtures :projects

  def setup
    super
    @uploaded = {
      disk_filename: '230105094726_1-TIOMAN_IMG_4391a.JPG',
      content_type: 'image/jpeg',
      original_filename: '1-TIOMAN_IMG_4391a.JPG',
      comment: '',
      tempfile_path: '/opt/redmine/files/2023/01/230105104724_1-TIOMAN_IMG_4391a.JPG',
      digest: '3fae7e571666c3b9a70067970a00396b5019e6ea94b26398d13e989e695a1a39'
    }
  end

  def test_initialize
    with_settings plugin_redmine_dmsf: { 'empty_minor_version_by_default' => '1' } do
      upload = DmsfUpload.new(@project1, nil, @uploaded)
      assert_equal 1, upload.major_version
      assert_nil upload.minor_version
    end
    with_settings plugin_redmine_dmsf: { 'empty_minor_version_by_default' => nil } do
      upload = DmsfUpload.new(@project1, nil, @uploaded)
      assert_equal 0, upload.major_version
      assert_equal 0, upload.minor_version
    end
  end
end
