# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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

class DmsfFileRevisionTest < RedmineDmsf::Test::UnitTest

  include Redmine::I18n

  fixtures :dmsf_locks, :dmsf_workflows, :dmsf_folders, :dmsf_files, :dmsf_file_revisions
         
  def setup
    super
    @revision1 = DmsfFileRevision.find 1
    @revision2 = DmsfFileRevision.find 2
    @revision3 = DmsfFileRevision.find 3
    @revision5 = DmsfFileRevision.find 5
    @revision8 = DmsfFileRevision.find 8
    @wf1 = DmsfWorkflow.find 1
  end

  def test_delete_restore
    @revision5.delete false
    assert @revision5.deleted?,
      "File revision #{@revision5.name} hasn't been deleted"
    @revision5.restore
    assert !@revision5.deleted?,
      "File revision #{@revision5.name} hasn't been restored"
  end

  def test_destroy
    @revision5.delete true
    assert_nil DmsfFileRevision.find_by(id: @revision5.id)
  end

  def test_digest_type
    # Old type MD5
    assert_equal 'MD5', @revision1.digest_type
  end

  def test_new_storage_filename
    # Create a file.
    f = DmsfFile.new
    f.project_id = 1
    f.name = 'Testfile.txt'
    f.dmsf_folder = nil
    f.notification = !Setting.plugin_redmine_dmsf['dmsf_default_notifications'].blank?
    f.save

    # Create two new revisions, r1 and r2
    r1 = DmsfFileRevision.new
    r1.minor_version = 0
    r1.major_version = 1
    r1.dmsf_file = f
    r1.user = User.current
    r1.name = 'Testfile.txt'
    r1.title = DmsfFileRevision.filename_to_title(r1.name)
    r1.description = nil
    r1.comment = nil
    r1.mime_type = nil
    r1.size = 4

    r2 = r1.clone
    r2.minor_version = 1

    assert r1.valid?
    assert r2.valid?

    # This is a very stupid since the generation and storing of files below must be done during the
    # same second, so wait until the microsecond part of the DateTime is less than 10 ms, should be
    # plenty of time to do the rest then.
    wait_timeout = 2000
    while DateTime.current.usec > 10000
        wait_timeout -= 10
        if wait_timeout <= 0
            flunk 'Waited too long.'
        end
        sleep 0.01
    end

    # First, generate the r1 storage filename and save the file
    r1.disk_filename = r1.new_storage_filename
    assert r1.save
    # Just make sure the file exists
    File.open(r1.disk_file, 'wb') do |f|
        f.write '1234'
    end

    # Directly after the file has been stored generate the r2 storage filename.
    # Hopefully the seconds part of the DateTime.current has not changed and the generated filename will
    # be on the same second but it should then be increased by 1.
    r2.disk_filename = r2.new_storage_filename
    assert_not_equal r1.disk_filename, r2.disk_filename, 'The disk filename should not be equal for two revisions.'
  end

  def test_workflow_tooltip
    @revision2.set_workflow @wf1.id, 'start'
    assert_equal 'John Smith', @revision2.workflow_tooltip
  end

  def test_version
    @revision1.major_version = 1
    @revision1.minor_version = 0
    assert_equal '1.0', @revision1.version
    @revision1.major_version = -('A'.ord)
    @revision1.minor_version = -(' '.ord)
    assert_equal 'A', @revision1.version
    @revision1.major_version = -('A'.ord)
    @revision1.minor_version = 0
    assert_equal 'A.0', @revision1.version
  end

  def test_increase_version
    # 1.0 -> 1.1
    @revision1.major_version = 1
    @revision1.minor_version = 0
    @revision1.increase_version(1)
    assert_equal 1, @revision1.major_version
    assert_equal 1, @revision1.minor_version
    # 1.0 -> 2.0
    @revision1.major_version = 1
    @revision1.minor_version = 0
    @revision1.increase_version(2)
    assert_equal 2, @revision1.major_version
    assert_equal 0, @revision1.minor_version
    # 1.1 -> 2.0
    @revision1.major_version = 1
    @revision1.minor_version = 1
    @revision1.increase_version(2)
    assert_equal 2, @revision1.major_version
    assert_equal 0, @revision1.minor_version
    # A -> A.1
    @revision1.major_version = -('A'.ord)
    @revision1.minor_version = -(' '.ord)
    @revision1.increase_version(1)
    assert_equal -('A'.ord), @revision1.major_version
    assert_equal 1, @revision1.minor_version
    # A -> B
    @revision1.major_version = -('A'.ord)
    @revision1.minor_version = -(' '.ord)
    @revision1.increase_version(2)
    assert_equal -('B'.ord), @revision1.major_version
    assert_equal -(' '.ord), @revision1.minor_version
    # A.1 -> B
    @revision1.major_version = -('A'.ord)
    @revision1.minor_version = 1
    @revision1.increase_version(2)
    assert_equal -('B'.ord), @revision1.major_version
    assert_equal -(' '.ord), @revision1.minor_version
  end

  def test_description_max_length
    @revision1.description = 'a' * 2.kilobytes
    assert !@revision1.save
    @revision1.description = 'a' * 1.kilobyte
    assert @revision1.save
  end

  def test_protocol_txt
    assert !@revision1.protocol
  end

  def test_protocol_doc
    @revision1.mime_type = Redmine::MimeType.of('test.doc')
    assert_equal 'ms-word', @revision1.protocol
  end

  def test_protocol_docx
    @revision1.mime_type = Redmine::MimeType.of('test.docx')
    assert_equal 'ms-word', @revision1.protocol
  end

  def test_protocol_odt
    @revision1.mime_type = Redmine::MimeType.of('test.odt')
    assert_equal 'ms-word', @revision1.protocol
  end

  def test_protocol_xls
    @revision1.mime_type = Redmine::MimeType.of('test.xls')
    assert_equal 'ms-excel', @revision1.protocol
  end

  def test_protocol_xlsx
    @revision1.mime_type = Redmine::MimeType.of('test.xlsx')
    assert_equal 'ms-excel', @revision1.protocol
  end

  def test_protocol_ods
    @revision1.mime_type = Redmine::MimeType.of('test.ods')
    assert_equal 'ms-excel', @revision1.protocol
  end

  def test_obsolete
    assert @revision1.obsolete
    assert_equal DmsfWorkflow::STATE_OBSOLETE, @revision1.workflow
  end

  def test_obsolete_locked
    User.current = @admin
    @revision1.dmsf_file.lock!
    User.current = @jsmith
    assert !@revision1.obsolete
    assert_equal 1, @revision1.errors.count
    assert @revision1.errors.full_messages.to_sentence.include?(l(:error_file_is_locked))
  end

  def test_minor_version_cannot_be_nil
    @revision1.minor_version = nil
    assert !@revision1.save
    assert @revision1.errors.full_messages.to_sentence.include?('Minor version cannot be blank')
  end

  def test_major_version_cannot_be_nil
    @revision1.major_version = nil
    assert !@revision1.save
    assert @revision1.errors.full_messages.to_sentence.include?('Major version cannot be blank')
  end

  def test_size_validation
    Setting.attachment_max_size = '1'
    @revision1.size = 2.kilobytes
    assert !@revision1.valid?
  end

end