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

# Plugin tests
class DmsfZipTest < RedmineDmsf::Test::HelperTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions, :attachments
  def setup
    @zip = RedmineDmsf::DmsfZip::Zip.new

    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.join('files', 'dmsf')
    FileUtils.cp_r File.join(File.expand_path('../../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
    @dmsf_file1 = DmsfFile.find(1)
    @dmsf_folder2 = DmsfFolder.find(2)
    set_fixtures_attachments_directory
    @attachment6 = Attachment.find(6)
  end

  def teardown
    # Delete our tmp folder
    FileUtils.rm_rf DmsfFile.storage_path
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def test_add_dmsf_file
    @zip.add_dmsf_file @dmsf_file1
    assert_equal 1, @zip.dmsf_files.size
    zip_file = @zip.finish
    Zip::File.open(zip_file) do |file|
      file.each do |entry|
        assert_equal @dmsf_file1.last_revision.name, entry.name
      end
    end
  end

  def test_add_attachment
    assert File.exist?(@attachment6.diskfile), @attachment6.diskfile
    @zip.add_attachment @attachment6, @attachment6.filename
    assert_equal 0, @zip.dmsf_files.size
    zip_file = @zip.finish
    Zip::File.open(zip_file) do |file|
      file.each do |entry|
        assert_equal @attachment6.filename, entry.name
      end
    end
  end

  def test_add_raw_file
    filename = 'data.txt'
    content = '1,2,3'
    @zip.add_raw_file filename, content
    assert_equal 0, @zip.dmsf_files.size
    zip_file = @zip.finish
    Zip::File.open(zip_file) do |file|
      file.each do |entry|
        assert_equal filename, entry.name
        assert_equal content, entry.get_input_stream.read
      end
    end
  end

  def test_read
    @zip.add_dmsf_file @dmsf_file1
    assert_not_empty @zip.read
  end

  def test_finish
    @zip.add_dmsf_file @dmsf_file1
    zip_file = @zip.finish
    assert File.exist?(zip_file)
  end

  def test_close
    @zip.add_dmsf_file @dmsf_file1
    assert @zip.close
  end
end
