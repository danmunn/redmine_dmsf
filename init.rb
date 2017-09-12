# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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
  unless Redmine::Plugin.installed?(:easy_extensions)
    name 'DMSF'
    url 'http://www.redmine.org/plugins/dmsf'
    author_url 'https://github.com/danmunn/redmine_dmsf/graphs/contributors'
  else
    name 'Easy DMS'
    url 'https://www.easyredmine.com'
    author_url 'https://www.easyredmine.com'
  end
  author 'Vít Jonáš / Daniel Munn / Karel Pičman'
  description 'Document Management System Features'
  version '1.6.0'

  requires_redmine :version_or_higher => '3.3.0'

  settings  :partial => 'settings/dmsf_settings',
            :default => {
              'dmsf_max_file_upload' => '0',
              'dmsf_max_file_download' => '0',
              'dmsf_max_email_filesize' => '0',
              'dmsf_max_ajax_upload_filesize' => '100',
              'dmsf_storage_directory' => 'files/dmsf',
              'dmsf_index_database' => 'files/dmsf_index',
              'dmsf_stemming_lang' => 'english',
              'dmsf_stemming_strategy' => 'STEM_NONE',
              'dmsf_webdav' => '1',
              'dmsf_display_notified_recipients' => 0,
              'dmsf_global_title_format' => '',
              'dmsf_columns' => %w(title size modified version workflow author),
              'dmsf_webdav_ignore' => '^(\._|\.DS_Store$|Thumbs.db$)',
              'dmsf_webdav_disable_versioning' => '^\~\$|\.tmp$',
              'dmsf_keep_documents_locked' => false,
              'dmsf_act_as_attachable' => false,
              'dmsf_show_system_folders' => false
            }

  # Uncomment to remove the original Documents from searching (replaced with DMSF)
  # Redmine::Search.available_search_types.delete('documents')
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
