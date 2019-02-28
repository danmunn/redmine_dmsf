# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

require File.expand_path('../../../test_helper', __FILE__)

class DmsfFileApiTest < RedmineDmsf::Test::IntegrationTest
  include Redmine::I18n

  fixtures :projects, :users, :dmsf_files, :dmsf_file_revisions, :members, :roles, :member_roles

  def setup
    @admin = User.find 1
    @jsmith = User.find 2
    @file1 = DmsfFile.find 1
    Setting.rest_api_enabled = '1'
    @role = Role.find_by(name: 'Manager')
    @project1 = Project.find 1
    @project1.enable_module! :dmsf
    @token = Token.create!(user: @jsmith, action: 'api')
    @dmsf_storage_directory = Setting.plugin_redmine_dmsf['dmsf_storage_directory']
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = 'files/dmsf'
    FileUtils.cp_r File.join(File.expand_path('../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
  end

  def teardown
    # Delete our tmp folder
    begin
      FileUtils.rm_rf DmsfFile.storage_path
    rescue Exception => e
      error e.message
    end
    Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = @dmsf_storage_directory
  end

  def test_truth
    assert_kind_of User, @admin
    assert_kind_of User, @jsmith
    assert_kind_of DmsfFile, @file1
    assert_kind_of Role, @role
    assert_kind_of Project, @project1
  end

  def test_get_document
    @role.add_permission! :view_dmsf_files
    #curl -v -H "Content-Type: application/xml" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/17216.xml
    get "/dmsf/files/#{@file1.id}.xml?key=#{@token.value}"
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    # <?xml version="1.0" encoding="UTF-8"?>
    # <dmsf_file>
    #   <id>1</id>
    #   <title>Test File</title>
    #   <name>test.txt</name>
    #   <project_id>1</project_id>
    #   <content_url>http://www.example.com/dmsf/files/1/download</content_url>
    #   <dmsf_file_revisions type="array">
    #     <dmsf_file_revision>
    #       <id>5</id>
    #       <source_dmsf_file_revision_id/>
    #       <name>test5.txt</name>
    #       <content_url>http://www.example.com/dmsf/files/1/view?download=5</content_url>
    #       <size>4</size>
    #       <mime_type>text/plain</mime_type>
    #       <title>Test File</title>
    #       <description/>
    #       <workflow>1</workflow>
    #       <version>1.0</version>
    #       <comment/>
    #       <user_id>1</user_id>
    #       <created_at>2017-04-18T12:52:28Z</created_at>
    #       <updated_at>2019-01-15T15:56:15Z</updated_at>
    #       <dmsf_workflow_id/>
    #       <dmsf_workflow_assigned_by/>
    #       <dmsf_workflow_assigned_at/>
    #       <dmsf_workflow_started_by/>
    #       <dmsf_workflow_started_at/>
    #       <digest></digest>
    #     </dmsf_file_revision>
    #     <dmsf_file_revision>
    #       <id>1</id>
    #       <source_dmsf_file_revision_id/>
    #       <name>test.txt</name>
    #       <content_url>http://www.example.com/dmsf/files/1/view?download=1</content_url>
    #       <size>4</size>
    #       <mime_type>text/plain</mime_type>
    #       <title>Test File</title>
    #       <description>Some file :-)</description>
    #       <workflow>1</workflow>
    #       <version>1.0</version>
    #       <comment/>
    #       <user_id>1</user_id>
    #       <created_at>2017-04-18T12:52:27Z</created_at>
    #       <updated_at>2019-01-15T15:56:15Z</updated_at>
    #       <dmsf_workflow_id/>
    #       <dmsf_workflow_assigned_by>1</dmsf_workflow_assigned_by>
    #       <dmsf_workflow_assigned_at/>
    #       <dmsf_workflow_started_by>1</dmsf_workflow_started_by>
    #       <dmsf_workflow_started_at/>
    #       <digest>81dc9bdb52d04dc20036dbd8313ed055</digest>
    #     </dmsf_file_revision>
    #   </dmsf_file_revisions>
    # </dmsf_file>
    #puts response.body
    assert_select 'dmsf_file > id', text: @file1.id.to_s
    assert_select 'dmsf_file > title', text: @file1.title
    assert_select 'dmsf_file > name', text: @file1.name
    assert_select 'dmsf_file > project_id', text: @file1.project_id.to_s
    assert_select 'dmsf_file > content_url', text: "http://www.example.com/dmsf/files/#{@file1.id}/download"
    assert_select 'dmsf_file > dmsf_file_revisions > dmsf_file_revision', @file1.dmsf_file_revisions.all.size
    #curl -v -H "Content-Type: application/octet-stream" -X GET -u ${1}:${2} http://localhost:3000/dmsf/files/41532/download > file.txt
    get "/dmsf/files/#{@file1.id}/download.xml?key=#{@token.value}"
    assert_response :success
    assert_equal '123', @response.body
  end

  def test_upload_document
    @role.add_permission! :file_manipulation
    #curl --data-binary "@cat.gif" -H "Content-Type: application/octet-stream" -X POST -u ${1}:${2} http://localhost:3000/projects/12/dmsf/upload.xml?filename=cat.gif
    post "/projects/#{@project1.id}/dmsf/upload.xml?filename=test.txt&key=#{@token.value}", :params => 'File content', :headers => {"CONTENT_TYPE" => 'application/octet-stream'}
    assert_response :created
    assert_equal 'application/xml', response.content_type
    #<?xml version="1.0" encoding="UTF-8"?>
    # <upload>
    #   <token>2.8bb2564936980e92ceec8a5759ec34a8</token>
    # </upload>
    xml = Hash.from_xml(response.body)
    assert_kind_of Hash, xml['upload']
    ftoken = xml['upload']['token']
    assert_not_nil ftoken
    #curl -v -H "Content-Type: application/xml" -X POST --data "@file.xml" -u ${1}:${2} http://localhost:3000/projects/12/dmsf/commit.xml
    payload = %{<?xml version="1.0" encoding="utf-8" ?>
                <attachments>
                 <folder_id/>
                 <uploaded_file>
                   <name>test.txt</name>
                   <title>test.txt</title>
                   <description>REST API</description>
                   <comment>From API</comment>
                   <version/>
                   <token>#{ftoken}</token>
                 </uploaded_file>
                </attachments>}
    assert_difference 'DmsfFileRevision.count', +1 do
      post "/projects/#{@project1.id}/dmsf/commit.xml?key=#{@token.value}", :params => payload, :headers => {"CONTENT_TYPE" => 'application/xml'}
    end
    #<?xml version="1.0" encoding="UTF-8"?>
    #<dmsf_files total_count="1" type="array">
    # <file>
    #   <id>17229</id>
    #   <name>test.txt</name>
    # </file>
    # </dmsf_files> #
    assert_select 'dmsf_files > file > name', :text => 'test.txt'
    assert_response :success
    revision = DmsfFileRevision.order(:created_at).last
    assert revision && revision.size > 0
  end

  def test_delete_file
    @role.add_permission! :file_delete
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/dmsf/files/196118.xml
    delete "/dmsf/files/#{@file1.id}.xml?key=#{@token.value}", :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    @file1.reload
    assert_equal DmsfFile::STATUS_DELETED, @file1.deleted
    assert_equal User.current, @file1.deleted_by_user
  end

  def test_delete_file_no_permissions
    token = Token.create!(:user => @jsmith, :action => 'api')
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/dmsf/files/196118.xml
    delete "/dmsf/files/#{@file1.id}.xml?key=#{token.value}", :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :forbidden
  end

  def test_delete_folder_commit_yes
    @role.add_permission! :file_delete
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/dmsf/files/196118.xml&commit=yes
    delete "/dmsf/files/#{@file1.id}.xml?key=#{@token.value}&commit=yes", :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response :success
    assert_nil DmsfFile.find_by(id: @file1.id)
  end

  def test_delete_file_locked
    @role.add_permission! :file_delete
    User.current = @admin
    @file1.lock!
    User.current = @jsmith
    # curl -v -H "Content-Type: application/xml" -X DELETE -u ${1}:${2} http://localhost:3000/dmsf/files/196118.xml
    delete "/dmsf/files/#{@file1.id}.xml?key=#{@token.value}", :headers => {'CONTENT_TYPE' => 'application/xml'}
    assert_response 422
    # <?xml version="1.0" encoding="UTF-8"?>
    # <errors type="array">
    #   <error>Locked by Admin</error>
    # </errors>
    assert_select 'errors > error', :text => l(:title_locked_by_user, user: @admin.name)
    @file1.reload
    assert_equal DmsfFile::STATUS_ACTIVE, @file1.deleted
  end

end