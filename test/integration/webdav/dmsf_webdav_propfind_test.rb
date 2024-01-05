# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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
require 'uri'

# WebDAV PROPFIND tests
class DmsfWebdavPropfindTest < RedmineDmsf::Test::IntegrationTest
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_propfind_denied_for_anonymous
    process :propfind, '/dmsf/webdav/', params: nil, headers: @anonymous.merge!({ HTTP_DEPTH: '0' })
    assert_response :unauthorized
  end

  def test_propfind_depth0_on_root_for_user
    process :propfind, '/dmsf/webdav/', params: nil, headers: @jsmith.merge!({ HTTP_DEPTH: '0' })
    assert_response :multi_status
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_user
    process :propfind, '/dmsf/webdav/', params: nil, headers: @someone.merge!({ HTTP_DEPTH: '1' })
    assert_response :multi_status
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth0_on_root_for_admin
    process :propfind, '/dmsf/webdav/', params: nil, headers: @admin.merge!({ HTTP_DEPTH: '0' })
    assert_response :multi_status
    assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
    assert response.body.include?('<d:displayname>/</d:displayname>')
  end

  def test_propfind_depth1_on_root_for_admin_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      process :propfind, '/dmsf/webdav/', params: nil, headers: @admin.merge!({ HTTP_DEPTH: '1' })
      assert_response :multi_status
      assert response.body.include?('<d:href>http://www.example.com:80/dmsf/webdav/</d:href>')
      assert response.body.include?('<d:displayname>/</d:displayname>')
      # project.identifier should not match when using project names
      assert_not response.body.include?(
        "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>"
      )
      assert_not response.body.include?("<d:displayname>#{@project1.identifier}</d:displayname>")
      # but the project name should match
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/</d:href>")
      assert response.body.include?("<d:displayname>#{project1_name}</d:displayname>")
    end
  end

  def test_propfind_depth0_on_project1_for_non_member
    process :propfind,
            "/dmsf/webdav/#{@project1.identifier}",
            params: nil,
            headers: @someone.merge!({ HTTP_DEPTH: '0' })
    assert_response :success
  end

  def test_propfind_depth0_on_folder1_for_non_member
    process :propfind, "/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}",
            params: nil,
            headers: @someone.merge!({ HTTP_DEPTH: '0' })
    assert_response :not_found
  end

  def test_propfind_depth0_on_file1_for_non_member
    process :propfind, "/dmsf/webdav/#{@project1.identifier}/#{@file1.name}",
            params: nil,
            headers: @someone.merge!({ HTTP_DEPTH: '0' })
    assert_response :not_found
  end

  def test_propfind_depth0_on_project1_for_admin
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @admin.merge!({ HTTP_DEPTH: '0' })
    assert_response :multi_status
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    assert response.body.include?(
      "<d:displayname>#{RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)}</d:displayname>"
    )
  end

  def test_propfind_depth0_on_project1_for_admin_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      process :propfind,
              "/dmsf/webdav/#{@project1.identifier}",
              params: nil,
              headers: @admin.merge!({ HTTP_DEPTH: '0' })
      assert_response :not_found
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      process :propfind, "/dmsf/webdav/#{project1_uri}", params: nil, headers: @admin.merge!({ HTTP_DEPTH: '0' })
      assert_response :multi_status
      assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/</d:href>")
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      assert response.body.include?("<d:displayname>#{project1_name}</d:displayname>")
    end
  end

  def test_propfind_depth1_on_project1_for_admin
    process :propfind, "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @admin.merge!({ HTTP_DEPTH: '1' })
    assert_response :multi_status
    # Project
    assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/</d:href>")
    assert response.body.include?(
      "<d:displayname>#{RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)}</d:displayname>"
    )
    # Folders
    assert response.body.include?(
      "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder1.title}/</d:href>"
    )
    assert response.body.include?("<d:displayname>#{@folder1.title}</d:displayname>")
    assert response.body.include?(
      "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}/</d:href>"
    )
    assert response.body.include?("<d:displayname>#{@folder6.title}</d:displayname>")
    # Files
    assert response.body.include?(
      "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file1.name}</d:href>"
    )
    assert response.body.include?("<d:displayname>#{@file1.name}</d:displayname>")
    assert response.body.include?(
      "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file9.name}</d:href>"
    )
    assert response.body.include?("<d:displayname>#{@file9.name}</d:displayname>")
    assert response.body.include?(
      "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@file10.name}</d:href>"
    )
    assert response.body.include?("<d:displayname>#{@file10.name}</d:displayname>")
  end

  def test_propfind_depth1_on_project1_for_admin_with_project_names
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      process :propfind,
              "/dmsf/webdav/#{@project1.identifier}", params: nil, headers: @admin.merge!({ HTTP_DEPTH: '1' })
      assert_response :not_found
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      process :propfind, "/dmsf/webdav/#{project1_uri}", params: nil, headers: @admin.merge!({ HTTP_DEPTH: '1' })
      assert_response :multi_status
      # Project
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/</d:href>")
      # Folders
      project1_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_uri = Addressable::URI.escape(project1_name)
      assert response.body.include?(
        "<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/#{@folder1.title}/</d:href>"
      )
      assert response.body.include?("<d:displayname>#{@folder1.title}</d:displayname>")
      assert response.body.include?(
        "<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/#{@folder6.title}/</d:href>"
      )
      assert response.body.include?("<d:displayname>#{@folder6.title}</d:displayname>")
      # Files
      assert response.body.include?(
        "<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/#{@file1.name}</d:href>"
      )
      assert response.body.include?("<d:displayname>#{@file1.name}</d:displayname>")
      assert response.body.include?(
        "<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/#{@file9.name}</d:href>"
      )
      assert response.body.include?("<d:displayname>#{@file9.name}</d:displayname>")
      assert response.body.include?(
        "<d:href>http://www.example.com:80/dmsf/webdav/#{project1_uri}/#{@file10.name}</d:href>"
      )
      assert response.body.include?("<d:displayname>#{@file10.name}</d:displayname>")
    end
  end

  def test_propfind_depth1_on_root_for_admin
    with_settings plugin_redmine_dmsf: { 'dmsf_webdav_use_project_names' => '1', 'dmsf_webdav' => '1' } do
      project1_new_name = RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1)
      project1_new_uri = ERB::Util.url_encode(project1_new_name)
      process :propfind, "/dmsf/webdav/#{project1_new_uri}", params: nil, headers: @admin.merge!({ HTTP_DEPTH: '1' })
      assert_response :multi_status
      assert response.body.include?("<d:href>http://www.example.com:80/dmsf/webdav/#{project1_new_uri}/</d:href>")
      assert response.body.include?("<d:displayname>#{project1_new_name}</d:displayname>")
    end
  end

  def test_propfind_for_subproject
    process :propfind, "/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}",
            params: nil,
            headers: @admin.merge!({ HTTP_DEPTH: '1' })
    assert_response :multi_status
    assert response.body.include?(
      "<d:href>http://www.example.com:80/dmsf/webdav/#{@project1.identifier}/#{@project5.identifier}/</d:href>"
    )
    assert response.body.include?(
      "<d:displayname>#{RedmineDmsf::Webdav::ProjectResource.create_project_name(@project5)}</d:displayname>"
    )
  end
end
