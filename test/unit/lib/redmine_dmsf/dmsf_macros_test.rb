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

# Macros tests
class DmsfMacrosTest < RedmineDmsf::Test::HelperTest
  include ApplicationHelper
  include ActionView::Helpers
  include ActionDispatch::Routing
  include ERB::Util
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    User.current = @jsmith
    default_url_options[:host] = 'www.example.com'
    @file1 = DmsfFile.find_by(id: 1)
    @file6 = DmsfFile.find_by(id: 6)  # video
    @file7 = DmsfFile.find_by(id: 7)  # image
    @folder1 = DmsfFolder.find_by(id: 1)
  end

  # {{dmsf(file_id [, title [, revision_id]])}}
  def test_macro_dmsf
    text = textilizable("{{dmsf(#{@file1.id})}}")
    assert text.include?(@file1.title), text
  end

  def test_macro_dmsf_file_not_found
    text = textilizable('{{dmsf(99)}}')
    assert text.include?('{{dmsf(99)}}'), text
  end

  def test_macro_dmsf_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsf(#{@file1.id})}}")
    assert text.exclude?(@file1.title), text
  end

  def test_macro_dmsf_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsf(#{@file1.id})}}")
    assert text.exclude?(@file1.title), text
  end

  def test_macro_dmsf_custom_title
    text = textilizable("{{dmsf(#{@file1.id}, xyz)}}")
    assert text.include?('xyz'), text
  end

  def test_macro_dmsf_custom_title_aprostrophes
    text = textilizable("{{dmsf(#{@file1.id}, 'xyz')}}")
    assert text.include?('xyz'), text
  end

  def test_macro_dmsf_custom_title_and_revision
    text = textilizable("{{dmsf(#{@file1.id}, '', 1)}}")
    assert text.include?('download=1'), text
  end

  # {{dmsff([folder_id [, title]])}}
  def test_macro_dmsff
    text = textilizable("{{dmsff(#{@folder1.id})}}")
    assert text.include?(@folder1.title), text
  end

  def test_macro_dmsff_no_permissions
    @manager_role.remove_permission! :view_dmsf_folders
    text = textilizable("{{dmsf(#{@folder1.id})}}")
    assert text.exclude?(@folder1.title), text
  end

  def test_macro_dmsff_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsf(#{@folder1.id})}}")
    assert text.exclude?(@folder1.title), text
  end

  def test_macro_dmsff_custom_title
    text = textilizable("{{dmsf(#{@folder1.id}, xyz)}}")
    assert text.include?('xyz'), text
  end

  def test_macro_dmsff_custom_title_aprostrophes
    text = textilizable("{{dmsf(#{@folder1.id}, 'xyz')}}")
    assert text.include?('xyz'), text
  end

  # {{dmsfd(document_id [, title])}}
  def test_macro_dmsfd
    text = textilizable("{{dmsfd(#{@file1.id})}}")
    assert text.include?(@file1.title), text
  end

  def test_macro_dmsfd_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsfd(#{@file1.id})}}")
    assert text.exclude?(@file1.title), text
  end

  def test_macro_dmsfd_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsfd(#{@file1.id})}}")
    assert text.exclude?(@file1.title), text
  end

  def test_macro_dmsfd_custom_title
    text = textilizable("{{dmsfd(#{@file1.id}, xyz)}}")
    assert text.include?('xyz'), text
  end

  def test_macro_dmsfd_custom_title_aprostrophes
    text = textilizable("{{dmsfd(#{@file1.id}, 'xyz')}}")
    assert text.include?('xyz'), text
  end

  # {{dmsfdesc(document_id)}}
  def test_macro_dmsfdesc
    rev = @file1.last_revision
    rev.description = 'blabla'
    rev.save
    text = textilizable("{{dmsfdesc(#{@file1.id})}}")
    assert text.include?(rev.description), text
  end

  def test_macro_dmsfdesc_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    rev = @file1.last_revision
    rev.description = 'blabla'
    rev.save
    text = textilizable("{{dmsfdesc(#{@file1.id})}}")
    assert text.exclude?(rev.description), text
  end

  def test_macro_dmsfdesc_dmsf_off
    @project1.disable_module! :dmsf
    rev = @file1.last_revision
    rev.description = 'blabla'
    rev.save
    text = textilizable("{{dmsfdesc(#{@file1.id})}}")
    assert text.exclude?(rev.description), text
  end

  # {{dmsfversion(document_id [, revision_id])}}
  def test_macro_dmsfdversion
    text = textilizable("{{dmsfversion(#{@file1.id})}}")
    assert text.include?(@file1.version), text
  end

  def test_macro_dmsfdversion_revision
    revision5 = DmsfFileRevision.find_by(id: 5)
    text = textilizable("{{dmsfversion(#{@file1.id}, #{revision5.id})}}")
    assert text.include?(revision5.version), text
  end

  def test_macro_dmsfdversion_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsfversion(#{@file1.id})}}")
    assert text.exclude?(@file1.version), text
  end

  def test_macro_dmsfdversion_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsfversion(#{@file1.id})}}")
    assert text.exclude?(@file1.version), text
  end

  # {{dmsflastupdate(document_id)}}
  def test_macro_dmsflastupdate
    text = textilizable("{{dmsflastupdate(#{@file1.id})}}")
    assert text.include?(format_time(@file1.last_revision.updated_at)), text
  end

  def test_macro_dmsflastupdate_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsflastupdate(#{@file1.id})}}")
    assert text.exclude?(format_time(@file1.last_revision.updated_at)), text
  end

  def test_macro_dmsflastupdate_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsflastupdate(#{@file1.id})}}")
    assert text.exclude?(format_time(@file1.last_revision.updated_at)), text
  end

  # {{dmsft(document_id)}}
  def test_macro_dmsft
    text = textilizable("{{dmsft(#{@file1.id}, 1)}}")
    assert text.include?(content_tag(:pre, @file1.text_preview(1))), text
  end

  def test_macro_dmsft_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsft(#{@file1.id}, 1)}}")
    assert text.exclude?(content_tag(:pre, @file1.text_preview(1))), text
  end

  def test_macro_dmsft_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsft(#{@file1.id}, 1)}}")
    assert text.exclude?(content_tag(:pre, @file1.text_preview(1))), text
  end

  # {{dmsf_image(file_id)}}
  def test_macro_dmsf_image
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    text = textilizable("{{dmsf_image(#{@file7.id})}}")
    assert text.include?(image_tag(url, alt: @file7.name, title: @file7.title, size: nil)), text
  end

  # {{dmsf_image(file_id file_id)}}
  def test_macro_dmsf_image_multiple
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    text = textilizable("{{dmsf_image(#{@file7.id} #{@file7.id})}}")
    link = image_tag(url, alt: @file7.name, title: @file7.title, size: nil)
    assert text.include?(link + link), text
  end

  def test_macro_dmsf_image_size
    size = '50%'
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    text = textilizable("{{dmsf_image(#{@file7.id}, size=#{size})}}")
    assert text.include?(image_tag(url, alt: @file7.name, title: @file7.title, width: size, height: size)), text
    # TODO: arguments src and with and height are swapped
    # size = '300'
    # text = textilizable("{{dmsf_image(#{@file7.id}, size=#{size})}}")
    # assert text.include?(image_tag(url, alt: @file7.name, title: @file7.title, width: size, height: size)), text
    # TODO: arguments src and with and height are swapped
    # size = '640x480'
    # text = textilizable("{{dmsf_image(#{@file7.id}, size=#{size})}}")
    # assert text.include?(image_tag(url, alt: @file7.name, title: @file7.title, width: '640', height: '480')), text
    height = '480'
    text = textilizable("{{dmsf_image(#{@file7.id}, height=#{height})}}")
    assert text.include?(image_tag(url, alt: @file7.name, title: @file7.title, width: 'auto', height: height)), text
    width = '480'
    text = textilizable("{{dmsf_image(#{@file7.id}, width=#{height})}}")
    assert text.include?(image_tag(url, alt: @file7.name, title: @file7.title, width: width, height: 'auto')), text
  end

  def test_macro_dmsf_image_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    text = textilizable("{{dmsf_image(#{@file7.id})}}")
    assert text.exclude?(image_tag(url, alt: @file7.name, title: @file7.title, size: nil)), text
  end

  def test_macro_dmsf_image_dmsf_off
    @project1.disable_module! :dmsf
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    text = textilizable("{{dmsf_image(#{@file7.id})}}")
    assert text.exclude?(image_tag(url, alt: @file7.name, title: @file7.title, size: nil)), text
  end

  def test_macro_dmsf_image_not_image
    text = textilizable("{{dmsf_image(#{@file1.id})}}")
    assert text.include?(::I18n.t(:error_not_supported_image_format))
  end

  # {{dmsf_video(file_id)}}
  def test_macro_dmsf_video
    text = textilizable("{{dmsf_video(#{@file6.id})}}")
    url = static_dmsf_file_url(@file6, @file6.last_revision.name)
    assert text.include?(video_tag(url, controls: true, alt: @file6.name, title: @file6.title)), text
  end

  def test_macro_dmsf_video_size
    size = '50%'
    url = static_dmsf_file_url(@file6, @file6.last_revision.name)
    text = textilizable("{{dmsf_video(#{@file6.id}, size=#{size})}}")
    link = video_tag(url, controls: true, alt: @file6.name, title: @file6.title, width: size, height: size)
    assert text.include?(link), text
    size = '300'
    text = textilizable("{{dmsf_video(#{@file6.id}, size=#{size})}}")
    link = video_tag(url, controls: true, alt: @file6.name, title: @file6.title, width: size, height: size)
    assert text.include?(link), text
    size = '640x480'
    text = textilizable("{{dmsf_video(#{@file6.id}, size=#{size})}}")
    link = video_tag(url, controls: true, alt: @file6.name, title: @file6.title, width: '640', height: '480')
    assert text.include?(link), text
    height = '480'
    text = textilizable("{{dmsf_video(#{@file6.id}, height=#{height})}}")
    link = video_tag(url, controls: true, alt: @file6.name, title: @file6.title, width: 'auto', height: height)
    assert text.include?(link), text
    width = '480'
    text = textilizable("{{dmsf_video(#{@file6.id}, width=#{height})}}")
    link = video_tag(url, controls: true, alt: @file6.name, title: @file6.title, width: width, height: 'auto')
    assert text.include?(link), text
  end

  def test_macro_dmsf_video_no_permissions
    @developer_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsf_video(#{@file6.id})}}")
    url = static_dmsf_file_url(@file6, @file6.last_revision.name)
    assert text.exclude?(video_tag(url, controls: true, alt: @file6.name, title: @file6.title)), text
  end

  def test_macro_dmsf_video_dmsf_off
    @project2.disable_module! :dmsf
    text = textilizable("{{dmsf_video(#{@file6.id})}}")
    url = static_dmsf_file_url(@file6, @file6.last_revision.name)
    assert text.exclude?(video_tag(url, controls: true, alt: @file6.name, title: @file6.title)), text
  end

  def test_macro_dmsf_video_not_video
    text = textilizable("{{dmsf_video(#{@file7.id})}}")
    assert text.include?(::I18n.t(:error_not_supported_video_format)), text
  end

  # {{dmsftn(file_id)}}
  def test_macro_dmsftn
    text = textilizable("{{dmsftn(#{@file7.id})}}")
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    img = image_tag(url, alt: @file7.name, title: @file7.title, width: 'auto', height: 200)
    link = link_to(img,
                   url,
                   target: '_blank',
                   rel: 'noopener',
                   title: h(@file7.last_revision.try(:tooltip)),
                   'data-downloadurl' => "#{@file7.last_revision.detect_content_type}:#{h(@file7.name)}:#{url}")
    assert text.include?(link), text
  end

  # {{dmsftn(file_id file_id)}}
  def test_macro_dmsftn_multiple
    text = textilizable("{{dmsftn(#{@file7.id} #{@file7.id})}}")
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    img = image_tag(url, alt: @file7.name, title: @file7.title, width: 'auto', height: 200)
    link = link_to(img, url, target: '_blank',
                             rel: 'noopener',
                             title: h(@file7.last_revision.try(:tooltip)),
                             'data-downloadurl': 'image/gif:test.gif:http://www.example.com/dmsf/files/7/test.gif')
    assert text.include?(link + link), text
  end

  # {{dmsftn(file_id size=300)}}
  def test_macro_dmsftn_size
    url = static_dmsf_file_url(@file7, @file7.last_revision.name)
    size = '300'
    text = textilizable("{{dmsftn(#{@file7.id}, size=#{size})}}")
    img = image_tag(url, alt: @file7.name, title: @file7.title, size: size)
    link = link_to(img,
                   url,
                   target: '_blank',
                   rel: 'noopener',
                   title: h(@file7.last_revision.try(:tooltip)),
                   'data-downloadurl' => "#{@file7.last_revision.detect_content_type}:#{h(@file7.name)}:#{url}")
    assert text.include?(link), text
    # TODO: arguments src and with and height are swapped
    # size = '640x480'
    # text = textilizable("{{dmsftn(#{@file7.id}, size=#{size})}}")
    # img = image_tag(url, alt: @file7.name, title: @file7.title, width: 640, height: 480)
    # link = link_to(img,
    #                url,
    #                target: '_blank',
    #                rel: 'noopener',
    #                title: h(@file7.last_revision.try(:tooltip)),
    #                'data-downloadurl' => "#{@file7.last_revision.detect_content_type}:#{h(@file7.name)}:#{url}")
    # assert text.include?(link), text
    height = '480'
    text = textilizable("{{dmsftn(#{@file7.id}, height=#{height})}}")
    img = image_tag(url, alt: @file7.name, title: @file7.title, width: 'auto', height: 480)
    link = link_to(img, url, target: '_blank',
                             rel: 'noopener',
                             title: h(@file7.last_revision.try(:tooltip)),
                             'data-downloadurl': 'image/gif:test.gif:http://www.example.com/dmsf/files/7/test.gif')
    assert text.include?(link), text
    width = '640'
    text = textilizable("{{dmsftn(#{@file7.id}, width=#{width})}}")
    img = image_tag(url, alt: @file7.name, title: @file7.title, width: 640, height: 'auto')
    link = link_to(img,
                   url,
                   target: '_blank',
                   rel: 'noopener',
                   title: h(@file7.last_revision.try(:tooltip)),
                   'data-downloadurl' => "#{@file7.last_revision.detect_content_type}:#{h(@file7.name)}:#{url}")
    assert text.include?(link), text
  end

  def test_macro_dmsftn_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsftn(#{@file7.id})}}")
    url = view_dmsf_file_url(@file7)
    img = image_tag(url, alt: @file7.name, title: @file7.title, width: 'auto', height: 200)
    assert text.exclude?(link_to(img, url, title: h(@file7.last_revision.try(:tooltip)))), text
  end

  def test_macro_dmsftn_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsftn(#{@file7.id})}}")
    url = view_dmsf_file_url(@file7)
    img = image_tag(url, alt: @file7.name, title: @file7.title, width: 'auto', height: 200)
    assert text.exclude?(link_to(img, url, title: h(@file7.last_revision.try(:tooltip)))), text
  end

  def test_macro_dmsftn_not_image
    text = textilizable("{{dmsftn(#{@file1.id})}}")
    assert text.include?(::I18n.t(:error_not_supported_image_format))
  end

  # {{dmsfw(file_id)}}
  def test_macro_dmsfw
    text = textilizable("{{dmsfw(#{@file1.id})}}")
    assert text.include?(@file1.last_revision.workflow_str(false)), text
  end

  def test_macro_dmsfw_no_permissions
    @manager_role.remove_permission! :view_dmsf_files
    text = textilizable("{{dmsfw(#{@file1.id})}}")
    assert text.include?(::I18n.t(:notice_not_authorized))
  end

  def test_macro_dmsfw_dmsf_off
    @project1.disable_module! :dmsf
    text = textilizable("{{dmsfw(#{@file1.id})}}")
    assert text.include?(::I18n.t(:notice_not_authorized))
  end
end
