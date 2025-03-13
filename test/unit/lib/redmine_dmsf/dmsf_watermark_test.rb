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

require File.expand_path('../../../../test_helper', __FILE__)

# Watermark tests
class DmsfWatermarkTest < RedmineDmsf::Test::HelperTest
  fixtures :dmsf_files, :dmsf_file_revisions

  def setup
    super
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.join('files', 'dmsf')
    FileUtils.cp_r File.join(File.expand_path('../../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    @dmsf_file7 = DmsfFile.find(7) # GIF
    @dmsf_file8 = DmsfFile.find(8) # PDF
    User.current = @jsmith
  end

  def teardown
    # Delete our tmp folder
    FileUtils.rm_rf DmsfFile.storage_path
    DmsfFile.clear_previews
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def test_image
    target = File.join(DmsfFile.previews_storage_path, File.basename(@dmsf_file7.last_revision.disk_file.to_s))
    watermarked = RedmineDmsf::Watermark.generate_image(@dmsf_file7.last_revision.disk_file, target)
    size_orig = File.size(@dmsf_file7.last_revision.disk_file)
    size_target = File.size(watermarked)
    FileUtils.rm_f watermarked
    assert_not_equal 0, size_target
    assert_not_equal size_orig, size_target
  end

  def test_pdf
    target = File.join(DmsfFile.previews_storage_path, File.basename(@dmsf_file8.last_revision.disk_file.to_s))
    watermarked = RedmineDmsf::Watermark.generate_pdf(@dmsf_file8.last_revision.disk_file, target)
    size_orig = File.size(@dmsf_file8.last_revision.disk_file)
    size_target = File.size(watermarked)
    FileUtils.rm_f watermarked
    assert_not_equal 0, size_target
    assert_not_equal size_orig, size_target
  end

  def test_text
    # Skip seconds
    text = "#{User.current}\n#{Time.current.strftime('%Y-%m-%d %H:%M')}"
    assert RedmineDmsf::Watermark.text(normalize: true).start_with?(text)
    assert RedmineDmsf::Watermark.text(normalize: false).start_with?(text)
  end
end
