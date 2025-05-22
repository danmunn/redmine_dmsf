# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Daniel Munn <dan.munn@munnster.co.uk>, Karel Pičman <karel.picman@kontron.com>
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

source 'https://rubygems.org' do
  gem 'ox' # Dav4Rack
  gem 'rake' unless Dir.exist?(File.expand_path('../../redmine_dashboard', __FILE__))
  gem 'uuidtools'
  gem 'zip-zip' unless Dir.exist?(File.expand_path('../../vault', __FILE__))

  # Redmine extensions
  unless Dir.exist?(File.expand_path('../../easyproject', __FILE__))
    gem 'active_record_union'
    gem 'simple_enum'
    group :xapian do
      gem 'xapian-ruby'
    end
  end
  unless %w[easyproject easy_gantt custom_tables]
         .any? { |plugin| Dir.exist?(File.expand_path("../../#{plugin}", __FILE__)) }
    group :test do
      gem 'rails-controller-testing'
    end
  end
end
