#!/bin/bash
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-21 Karel Pičman <karel.picman@kontron.com>
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
#
# The script for GitLab Continous Integration

# Exit if any command fails
set -e

# Display the arguments (DB engine and branch)
echo "${1}, ${2}"

# Variables
REDMINE_REPO=http://svn.redmine.org/redmine/branches/5.0-stable/
REDMINE_PATH=/opt/redmine
PLUGINS_PATH="${REDMINE_PATH}/plugins"
DMSF_REPO=https://github.com/danmunn/redmine_dmsf.git

# Init
rm -rf "${REDMINE_PATH}"

# Clone Redmine
svn export "${REDMINE_REPO}" "${REDMINE_PATH}"

# Add the plugin
git clone -b $2 --single-branch --no-tags "$DMSF_REPO" "${PLUGINS_PATH}/redmine_dmsf"

# Prepare the database
cd "${REDMINE_PATH}"
cp "${PLUGINS_PATH}/redmine_dmsf/test/ci/$1.yml" "${REDMINE_PATH}/config/database.yml"
case $1 in

  mariadb)
    /etc/init.d/$1 start
    mariadb -e "CREATE DATABASE IF NOT EXISTS test CHARACTER SET utf8mb4"
    mariadb -e "CREATE USER 'redmine'@'localhost' IDENTIFIED BY 'redmine'";
    mariadb -e "GRANT ALL PRIVILEGES ON test.* TO 'redmine'@'localhost'";
    ;;

  postgres)
    /etc/init.d/$1ql start
    su -c "psql -c \"CREATE ROLE redmine LOGIN ENCRYPTED PASSWORD 'redmine' NOINHERIT VALID UNTIL 'infinity';\"" postgres
    su -c "psql -c \"CREATE DATABASE test WITH ENCODING='UTF8' OWNER=redmine;\"" postgres
    su -c "psql -c \"ALTER USER redmine CREATEDB;\"" postgres
    ;;

  sqlite3)
    ;;

  *)
    echo 'Missing argument'
    exit 1
    ;;
esac

# Install Redmine
cd "${REDMINE_PATH}"
gem install bundler
RAILS_ENV=test bundle config set --local without 'rmagick xapian development'
RAILS_ENV=test bundle install
RAILS_ENV=test bundle exec rake generate_secret_token
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake redmine:plugins:migrate
RAILS_ENV=test REDMINE_LANG=en bundle exec rake redmine:load_default_data

# Run Redmine tests
#RAILS_ENV=test bundle exec rake test

# Run DMSF tests

# Prepare the environment
cp config/additional_environment.rb.example config/additional_environment.rb
echo "# Redmine DMSF's WebDAV" >> config/additional_environment.rb
echo "require File.dirname(__FILE__) + '/plugins/redmine_dmsf/lib/redmine_dmsf/webdav/custom_middleware'" >> config/additional_environment.rb
echo "config.middleware.insert_before ActionDispatch::Cookies, RedmineDmsf::Webdav::CustomMiddleware" >> config/additional_environment.rb

# Standard tests
bundle exec rake redmine:plugins:test:units NAME=redmine_dmsf RAILS_ENV=test
bundle exec rake redmine:plugins:test:functionals NAME=redmine_dmsf RAILS_ENV=test
bundle exec rake redmine:plugins:test:integration NAME=redmine_dmsf RAILS_ENV=test
# Libraries
ruby plugins/redmine_dmsf/test/unit/lib/redmine_dmsf/dmsf_macros_test.rb RAILS_ENV=test
ruby plugins/redmine_dmsf/test/unit/lib/redmine_dmsf/dmsf_plugin_test.rb RAILS_ENV=test
# Helpers
ruby plugins/redmine_dmsf/test/helpers/dmsf_helper_test.rb RAILS_ENV=test
ruby plugins/redmine_dmsf/test/helpers/dmsf_queries_helper_test.rb RAILS_ENV=test

# Litmus

# Prepare Redmine's environment for WebDAV testing
RAILS_ENV=test bundle exec rake redmine:dmsf_webdav_test_on

# Run Webrick server
bundle exec rails server -u webrick -e test -d

# Run Litmus tests (Omit 'http' tests due to 'timeout waiting for interim response' and locks due to complex bogus conditional)
TESTS="basic copymove props" litmus http://localhost:3000/dmsf/webdav/dmsf_test_project admin admin

# Shutdown Webrick
kill `cat tmp/pids/server.pid`

# Clean up Redmine's environment from WebDAV testing
RAILS_ENV=test bundle exec rake redmine:dmsf_webdav_test_off

# Clean up database from the plugin changes
bundle exec rake redmine:plugins:migrate NAME=redmine_xapian VERSION=0 RAILS_ENV=test

case $1 in

  mariadb)
    /etc/init.d/$1 stop
    ;;

  postgres)
    /etc/init.d/$1ql stop
    ;;

  sqlite3)
    ;;

  *)
    echo 'Missing argument'
    exit 1
    ;;
esac

echo "$1 Okay"
