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

# Plugin tests
class DmsfPluginTest < RedmineDmsf::Test::HelperTest
  def test_present_yes
    assert RedmineDmsf::Plugin.present?(:redmine_dmsf)
  end

  def test_present_no
    assert_not RedmineDmsf::Plugin.present?(:redmine_dmsfx)
  end

  def test_an_obsolete_plugin_present_no
    # No such plugin is present
    assert_not RedmineDmsf::Plugin.an_obsolete_plugin_present?
  end

  def test_an_obsolete_plugin_present_yes
    # Create a fake redmine_checklists plugin
    path = Rails.root.join('plugins/redmine_resources')
    FileUtils.mkdir_p path
    assert RedmineDmsf::Plugin.an_obsolete_plugin_present?
    FileUtils.rm_rf path
  end
end
