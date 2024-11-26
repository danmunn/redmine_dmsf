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

# Main module
module RedmineDmsf
  # Settings
  class << self
    def dmsf_max_file_download
      Setting.plugin_redmine_dmsf['dmsf_max_file_download'].to_i
    end

    def dmsf_max_email_filesize
      Setting.plugin_redmine_dmsf['dmsf_max_email_filesize'].to_i
    end

    def dmsf_storage_directory
      value = Setting.plugin_redmine_dmsf['dmsf_storage_directory'].presence || 'files/dmsf'
      value.strip
    end

    def dmsf_index_database
      value = Setting.plugin_redmine_dmsf['dmsf_index_database'].presence || File.expand_path('dmsf_index', Rails.root)
      value.strip
    end

    def dmsf_stemming_lang
      value = Setting.plugin_redmine_dmsf['dmsf_stemming_lang'].presence || 'english'
      value.strip
    end

    def dmsf_stemming_strategy
      value = Setting.plugin_redmine_dmsf['dmsf_stemming_strategy'].presence || 'STEM_NONE'
      value.strip
    end

    def dmsf_webdav?
      if Setting.plugin_redmine_dmsf['dmsf_webdav'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_webdav']
      else
        Setting.plugin_redmine_dmsf['dmsf_webdav'].to_i.positive?
      end
    end

    def dmsf_display_notified_recipients?
      if Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients']
      else
        Setting.plugin_redmine_dmsf['dmsf_display_notified_recipients'].to_i.positive?
      end
    end

    def dmsf_global_title_format
      value = Setting.plugin_redmine_dmsf['dmsf_global_title_format'].presence || ''
      value.strip
    end

    def dmsf_columns
      Setting.plugin_redmine_dmsf['dmsf_columns'].presence || DmsfFolder::DEFAULT_COLUMNS
    end

    def dmsf_webdav_ignore
      value = Setting.plugin_redmine_dmsf['dmsf_webdav_ignore'].presence || '^(\._|\.DS_Store$|Thumbs.db$)'
      value.strip
    end

    def dmsf_webdav_disable_versioning
      value = Setting.plugin_redmine_dmsf['dmsf_webdav_disable_versioning'].presence || '^\~\$|\.tmp$'
      value.strip
    end

    def dmsf_keep_documents_locked?
      if Setting.plugin_redmine_dmsf['dmsf_keep_documents_locked'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_keep_documents_locked']
      else
        Setting.plugin_redmine_dmsf['dmsf_keep_documents_locked'].to_i.positive?
      end
    end

    def dmsf_act_as_attachable?
      if Setting.plugin_redmine_dmsf['dmsf_act_as_attachable?'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_act_as_attachable?']
      else
        Setting.plugin_redmine_dmsf['dmsf_act_as_attachable?'].to_i.positive?
      end
    end

    def dmsf_documents_email_from
      value = Setting.plugin_redmine_dmsf['dmsf_documents_email_from'].presence ||
              "#{User.current.name} <#{User.current.mail}>"
      value.strip
    end

    def dmsf_documents_email_reply_to
      value = Setting.plugin_redmine_dmsf['dmsf_documents_email_reply_to'].presence || ''
      value.strip
    end

    def dmsf_documents_email_links_only?
      if Setting.plugin_redmine_dmsf['dmsf_documents_email_links_only'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_documents_email_links_only']
      else
        Setting.plugin_redmine_dmsf['dmsf_documents_email_links_only'].to_i.positive?
      end
    end

    def dmsf_enable_cjk_ngrams?
      if Setting.plugin_redmine_dmsf['dmsf_enable_cjk_ngrams'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_enable_cjk_ngrams']
      else
        Setting.plugin_redmine_dmsf['dmsf_enable_cjk_ngrams'].to_i.positive?
      end
    end

    def dmsf_webdav_use_project_names?
      if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
      else
        Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'].to_i.positive?
      end
    end

    def dmsf_webdav_ignore_1b_file_for_authentication?
      if Setting.plugin_redmine_dmsf['dmsf_webdav_ignore_1b_file_for_authentication'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_webdav_ignore_1b_file_for_authentication']
      else
        Setting.plugin_redmine_dmsf['dmsf_webdav_ignore_1b_file_for_authentication'].to_i.positive?
      end
    end

    def dmsf_projects_as_subfolders?
      if Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders']
      else
        Setting.plugin_redmine_dmsf['dmsf_projects_as_subfolders'].to_i.positive?
      end
    end

    def only_approval_zero_minor_version?
      if Setting.plugin_redmine_dmsf['only_approval_zero_minor_version'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['only_approval_zero_minor_version']
      else
        Setting.plugin_redmine_dmsf['only_approval_zero_minor_version'].to_i.positive?
      end
    end

    def dmsf_max_notification_receivers_info
      Setting.plugin_redmine_dmsf['dmsf_max_notification_receivers_info'].to_i
    end

    def office_bin
      value = Setting.plugin_redmine_dmsf['office_bin'].presence || ''
      value.strip
    end

    def dmsf_global_menu_disabled?
      if Setting.plugin_redmine_dmsf['dmsf_global_menu_disabled'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['dmsf_global_menu_disabled']
      else
        Setting.plugin_redmine_dmsf['dmsf_global_menu_disabled'].to_i.positive?
      end
    end

    def dmsf_default_query
      value = Setting.plugin_redmine_dmsf['dmsf_default_query'].presence || ''
      value.strip
    end

    def empty_minor_version_by_default?
      if Setting.plugin_redmine_dmsf['empty_minor_version_by_default'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['empty_minor_version_by_default']
      else
        Setting.plugin_redmine_dmsf['empty_minor_version_by_default'].to_i.positive?
      end
    end

    def remove_original_documents_module?
      if Setting.plugin_redmine_dmsf['remove_original_documents_module'].is_a?(TrueClass)
        Setting.plugin_redmine_dmsf['remove_original_documents_module']
      else
        Setting.plugin_redmine_dmsf['remove_original_documents_module'].to_i.positive?
      end
    end

    def dmsf_webdav_authentication
      value = Setting.plugin_redmine_dmsf['dmsf_webdav_authentication'].presence || 'Basic'
      value.strip
    end
  end
end

# DMSF libraries

# Validators
require "#{File.dirname(__FILE__)}/../app/validators/dmsf_file_name_validator"
require "#{File.dirname(__FILE__)}/../app/validators/dmsf_max_file_size_validator"
require "#{File.dirname(__FILE__)}/../app/validators/dmsf_workflow_name_validator"
require "#{File.dirname(__FILE__)}/../app/validators/dmsf_url_validator"
require "#{File.dirname(__FILE__)}/../app/validators/dmsf_folder_parent_validator"

# Plugin's patches
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/formatting_helper_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/projects_helper_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/project_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/user_preference_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/user_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/issue_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/role_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/queries_controller_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/pdf_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/access_control_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/search_patch"
require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/custom_field_patch"

# A workaround for obsolete 'alias_method' usage in RedmineUp's plugins
def require_notifiable
  if defined?(EasyExtensions) || RedmineDmsf::Plugin.an_obsolete_plugin_present?
    require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/notifiable_ru_patch"
  else
    require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/notifiable_patch"
  end
end

if defined?(EasyExtensions)
  Rails.application.config.to_prepare { require_notifiable }
else
  require_notifiable
end

if defined?(EasyExtensions)
  require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/easy_crm_case_patch"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/attachable_patch"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/patches/easy_crm_cases_controller_patch.rb"
end

# Load up classes that make up our WebDAV solution ontop of Dav4rack
require "#{File.dirname(__FILE__)}/dav4rack"
require "#{File.dirname(__FILE__)}/redmine_dmsf/webdav/custom_middleware"
require "#{File.dirname(__FILE__)}/redmine_dmsf/webdav/base_resource"
require "#{File.dirname(__FILE__)}/redmine_dmsf/webdav/dmsf_resource"
require "#{File.dirname(__FILE__)}/redmine_dmsf/webdav/index_resource"
require "#{File.dirname(__FILE__)}/redmine_dmsf/webdav/project_resource"
require "#{File.dirname(__FILE__)}/redmine_dmsf/webdav/resource_proxy"

# Errors
require "#{File.dirname(__FILE__)}/redmine_dmsf/errors/dmsf_access_error"
require "#{File.dirname(__FILE__)}/redmine_dmsf/errors/dmsf_email_max_file_size_error"
require "#{File.dirname(__FILE__)}/redmine_dmsf/errors/dmsf_file_not_found_error"
require "#{File.dirname(__FILE__)}/redmine_dmsf/errors/dmsf_lock_error"
require "#{File.dirname(__FILE__)}/redmine_dmsf/errors/dmsf_zip_max_files_error"

# Hooks
def require_hooks
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/controllers/account_controller_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/controllers/issues_controller_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/controllers/search_controller_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/view_projects_form_hook"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/base_view_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/custom_field_view_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/issue_view_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/mailer_view_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/my_account_view_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/views/search_view_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/helpers/issues_helper_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/helpers/search_helper_hooks"
  require "#{File.dirname(__FILE__)}/redmine_dmsf/hooks/helpers/project_helper_hooks"
end

if defined?(EasyExtensions)
  Rails.application.config.to_prepare { require_hooks }
else
  require_hooks
end

# Macros
require "#{File.dirname(__FILE__)}/redmine_dmsf/macros"

# Field formats
require "#{File.dirname(__FILE__)}/redmine_dmsf/field_formats/dmsf_file_revision_format"
