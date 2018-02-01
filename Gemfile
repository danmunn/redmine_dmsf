# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-18 Karel Pičman <karel.picman@kontron.com>
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

source 'https://rubygems.org'

gem 'rubyzip', '>= 1.0.0'
gem 'zip-zip'
gem 'simple_enum'
gem 'uuidtools'
#gem 'dav4rack'
gem 'dav4rack', git: 'https://github.com/picman/dav4rack.git', branch: 'master'
gem 'dalli'
unless %w(easyproject easy_gantt).any? { |plugin| Dir.exist?(File.expand_path("../../#{plugin}", __FILE__)) }
  gem 'redmine_extensions', '~> 0.2.5'
end
