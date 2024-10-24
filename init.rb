# frozen_string_literal: true

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
  version '3.2.4'

  requires_redmine version_or_higher: '5.0.0'

  webdav = if Redmine::Plugin.installed?('easy_hosting_services') && EasyHostingServices::EasyMultiTenancy.activated?
             '1'
           end
  use_project_names = Redmine::Plugin.installed?('easy_extensions') ? '1' : nil

  settings partial: 'settings/dmsf_settings',
           default: {
             'dmsf_max_file_download' => 0,
             'dmsf_max_email_filesize' => 0,
             'dmsf_storage_directory' => 'files/dmsf',
             'dmsf_index_database' => File.expand_path('dmsf_index', Rails.root),
             'dmsf_stemming_lang' => 'english',
             'dmsf_stemming_strategy' => 'STEM_NONE',
             'dmsf_webdav' => webdav,
             'dmsf_display_notified_recipients' => nil,
             'dmsf_global_title_format' => '',
             'dmsf_columns' => %w[title size modified version workflow author],
             'dmsf_webdav_ignore' => '^(\._|\.DS_Store$|Thumbs.db$)',
             'dmsf_webdav_disable_versioning' => '^\~\$|\.tmp$',
             'dmsf_keep_documents_locked' => nil,
             'dmsf_act_as_attachable' => nil,
             'dmsf_documents_email_from' => '',
             'dmsf_documents_email_reply_to' => '',
             'dmsf_documents_email_links_only' => nil,
             'dmsf_enable_cjk_ngrams' => nil,
             'dmsf_webdav_use_project_names' => use_project_names,
             'dmsf_webdav_ignore_1b_file_for_authentication' => '1',
             'dmsf_projects_as_subfolders' => nil,
             'only_approval_zero_minor_version' => '0',
             'dmsf_max_notification_receivers_info' => 10,
             'office_bin' => 'libreoffice',
             'dmsf_global_menu_disabled' => nil,
             'dmsf_default_query' => nil,
             'empty_minor_version_by_default' => nil,
             'remove_original_documents_module' => nil,
             'dmsf_webdav_authentication' => 'Digest'
           }
end

require_relative 'after_init' unless Redmine::Plugin.installed?('easy_extensions')
