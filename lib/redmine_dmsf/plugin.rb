# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
#
# This file is part of Redmine DMSF plugin.
#
# Redmine DMSF plugin is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# Redmine DMSF plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with Redmine DMSF plugin. If not, see
# <https://www.gnu.org/licenses/>.

module RedmineDmsf
  # Plugin
  module Plugin
    # Checking physical presence of the plugin as Redmine::Plugin.installed? may return false due to alphabetical
    # registering of available plugins.
    def self.present?(id)
      Rails.root.join('plugins', id.to_s).exist?
    end

    # Return true if a plugin that overrides Redmine::Notifiable and use the deprecated method alias_method_chain is
    # present.
    # It is related especially to plugins made by AlphaNode and RedmineUP.
    def self.an_obsolete_plugin_present?
      plugins = %w[easyproject/easy_plugins/easy_money redmine_questions redmine_db redmine_passwords redmine_resources
                   redmine_products redmine_finance]
      plugins.each do |plugin|
        return true if Plugin.present?(plugin)
      end
      false
    end

    # Return true if the given gem is installed
    def self.lib_available?(path)
      require path
      true
    rescue LoadError => e
      Rails.logger.debug e.message
      false
    end
  end
end
