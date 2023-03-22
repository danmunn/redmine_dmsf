# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
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

require File.expand_path('../../../../test_helper', __FILE__)

class DmsfPluginTest < RedmineDmsf::Test::HelperTest

  def test_present_yes
    assert RedmineDmsf::Plugin.present?(:redmine_dmsf)
  end

  def test_present_no
    assert !RedmineDmsf::Plugin.present?(:redmine_dmsfx)
  end

  def test_an_osolete_plugin_present_no
    # No such plugin is present
    assert !RedmineDmsf::Plugin.an_osolete_plugin_present?
  end

  def test_an_osolete_plugin_present_yes
    # Create a fake redmine_checklists plugin
    path = File.join(Rails.root, 'plugins', 'redmine_contacts')
    Dir.mkdir(path) unless Dir.exist?(path)
    assert RedmineDmsf::Plugin.an_osolete_plugin_present?
    Dir.rmdir(path) if Dir.exist?(path)
  end

end
