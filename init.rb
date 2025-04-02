﻿# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
#  Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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
  name 'DMSF'
  url 'https://www.redmine.org/plugins/redmine_dmsf'
  author_url 'https://github.com/danmunn/redmine_dmsf/graphs/contributors'
  author 'Vít Jonáš / Daniel Munn / Karel Pičman'
  description 'Document Management System Features'
  version '4.1.2'

  requires_redmine version_or_higher: '6.0.0'

  webdav = if Redmine::Plugin.installed?('easy_hosting_services') && EasyHostingServices::EasyMultiTenancy.activated?
             '1'
           else
             '0'
           end
  use_project_names = defined?(EasyExtensions) ? '1' : '0'

  settings partial: 'settings/dmsf_settings',
           default: {
             'dmsf_max_file_download' => 0,
             'dmsf_max_email_filesize' => 0,
             'dmsf_storage_directory' => 'files/dmsf',
             'dmsf_index_database' => File.expand_path('dmsf_index', Rails.root),
             'dmsf_stemming_lang' => 'english',
             'dmsf_stemming_strategy' => 'STEM_NONE',
             'dmsf_webdav' => webdav,
             'dmsf_display_notified_recipients' => '0',
             'dmsf_global_title_format' => '',
             'dmsf_columns' => %w[title size modified version workflow author],
             'dmsf_webdav_ignore' => '^(\._|\.DS_Store$|Thumbs.db$)',
             'dmsf_webdav_disable_versioning' => '^\~\$|\.tmp$',
             'dmsf_keep_documents_locked' => '0',
             'dmsf_act_as_attachable' => '0',
             'dmsf_documents_email_from' => '',
             'dmsf_documents_email_reply_to' => '',
             'dmsf_documents_email_links_only' => '0',
             'dmsf_enable_cjk_ngrams' => '0',
             'dmsf_webdav_use_project_names' => use_project_names,
             'dmsf_webdav_ignore_1b_file_for_authentication' => '1',
             'dmsf_projects_as_subfolders' => '0',
             'only_approval_zero_minor_version' => '0',
             'dmsf_max_notification_receivers_info' => 10,
             'office_bin' => 'libreoffice',
             'dmsf_global_menu_disabled' => '0',
             'dmsf_default_query' => '0',
             'empty_minor_version_by_default' => '0',
             'remove_original_documents_module' => '0',
             'dmsf_webdav_authentication' => 'Digest',
             'dmsf_really_delete_files' => '0'
           }
end

require_relative 'after_init' unless defined?(EasyExtensions)
