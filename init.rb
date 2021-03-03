# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

Redmine::Plugin.register :redmine_dmsf do
  if Redmine::Plugin.installed?(:easy_extensions)
    name 'Easy DMS'
    url 'https://www.easyredmine.com'
    author_url 'https://www.easyredmine.com'
  else
    name 'DMSF'
    url 'https://www.redmine.org/plugins/redmine_dmsf'
    author_url 'https://github.com/danmunn/redmine_dmsf/graphs/contributors'
  end
  author 'Vít Jonáš / Daniel Munn / Karel Pičman'
  description 'Document Management System Features'
  version '2.4.6 devel'
  
  requires_redmine version_or_higher: '4.0.0'

  settings partial: 'settings/dmsf_settings',
            default: {
              'dmsf_max_file_download' => 0,
              'dmsf_max_email_filesize' => 0,
              'dmsf_storage_directory' => 'files/dmsf',
              'dmsf_index_database' => File.expand_path('dmsf_index', Rails.root),
              'dmsf_stemming_lang' => 'english',
              'dmsf_stemming_strategy' => 'STEM_NONE',
              'dmsf_webdav' => (Redmine::Plugin.installed?(:easy_hosting_services) && EasyHostingServices::EasyMultiTenancy.activated?) ? nil : '1',
              'dmsf_display_notified_recipients' => nil,
              'dmsf_global_title_format' => '',
              'dmsf_columns' => %w(title size modified version workflow author),
              'dmsf_webdav_ignore' => '^(\._|\.DS_Store$|Thumbs.db$)',
              'dmsf_webdav_disable_versioning' => '^\~\$|\.tmp$',
              'dmsf_keep_documents_locked' => nil,
              'dmsf_act_as_attachable' => nil,
              'dmsf_tmpdir' => Dir.tmpdir,
              'dmsf_documents_email_from' => '',
              'dmsf_documents_email_reply_to' => '',
              'dmsf_documents_email_links_only' => nil,
              'dmsf_enable_cjk_ngrams' => nil,
              'dmsf_webdav_use_project_names' => Redmine::Plugin.installed?(:easy_extensions) ? '1' : nil,
              'dmsf_webdav_ignore_1b_file_for_authentication' => '1',
              'dmsf_projects_as_subfolders' =>  nil
            }
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
