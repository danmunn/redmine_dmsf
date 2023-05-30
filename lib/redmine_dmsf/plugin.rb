# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2011-23 Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  # Plugin
  module Plugin
    # Checking physical presence of the plugin as Redmine::Plugin.installed? may return false due to alphabetical
    # registering of available plugins.
    def self.present?(id)
      Dir.exist? Rails.root.join('plugins', id.to_s)
    end

    # Return true if a plugin that overrides Redmine::Notifiable and use the deprecated method alias_method_chain is
    # present.
    # It is related especially to plugins made by AplhaNode and RedmineUP.
    def self.an_obsolete_plugin_present?
      plugins = %w[easyproject/easy_plugins/easy_money redmine_questions redmine_contacts redmine_db redmine_passwords
                   redmine_resources]
      plugins.each do |plugin|
        return true if Plugin.present?(plugin)
      end
      false
    end
  end
end
