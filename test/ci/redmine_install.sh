#!/bin/bash
# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
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

if [[ ! -v REDMINE_GIT_REPO ]]; then
  export REDMINE_GIT_REPO=git://github.com/redmine/redmine.git
fi
if [[ ! -v REDMINE_GIT_TAG ]]; then
  export REDMINE_GIT_TAG=4.1-stable
fi

clone()
{
  # Exit if the cloning fails
  set -e

  rm -rf ${PATH_TO_REDMINE}
  git clone -b ${REDMINE_GIT_TAG} --depth=100 --quiet ${REDMINE_GIT_REPO} ${PATH_TO_REDMINE}
}

test()
{
  # Exit if a test fails
  set -e

  cd ${PATH_TO_REDMINE}

  # Run tests within application
  bundle exec rake redmine:plugins:test:units NAME=redmine_dmsf RAILS_ENV=test
  bundle exec rake redmine:plugins:test:functionals NAME=redmine_dmsf RAILS_ENV=test
  bundle exec rake redmine:plugins:test:integration NAME=redmine_dmsf RAILS_ENV=test

  # Litmus
  # Prepare Redmine's environment for WebDAV testing
  bundle exec rake redmine:dmsf_webdav_test_on RAILS_ENV=test
  # Run Webrick server
  bundle exec rails server webrick -e test -d
  # Run Litmus tests
  litmus http://localhost:3000/dmsf/webdav/dmsf_test_project admin admin
  # Shutdown Webrick
  kill `cat tmp/pids/server.pid`
  # Clean up Redmine's environment from WebDAV testing
  bundle exec rake redmine:dmsf_webdav_test_off RAILS_ENV=test
}

uninstall()
{
  # Exit if the migration fails
  set -e

  cd ${PATH_TO_REDMINE}

  # clean up database
  bundle exec rake redmine:plugins:migrate NAME=redmine_dmsf VERSION=0 RAILS_ENV=test
}

install()
{
  # Exit if the installation fails
  set -e

  # cd to redmine folder
  cd ${PATH_TO_REDMINE}
  echo current directory is `pwd`

  # Create a link to the dmsf plugin
  ln -sf ${PATH_TO_DMSF} plugins/redmine_dmsf

  # Copy database.yml
  cp ${WORKSPACE}/database.yml config/

  # Install gems
  # Not ideal, but at present Travis-CI will not install with xapian enabled:
  bundle install --without xapian rmagick development RAILS_ENV=test

  # Run Redmine database migrations
  bundle exec rake db:migrate --trace RAILS_ENV=test

  # Load Redmine database default data  
  bundle exec rake redmine:load_default_data REDMINE_LANG=en RAILS_ENV=test

  # generate session store/secret token
  bundle exec rake generate_secret_token RAILS_ENV=test
  
  # Run the plugin database migrations
  bundle exec rake redmine:plugins:migrate RAILS_ENV=test
}

while getopts :ictu opt
do case "$opt" in
  c) clone; exit 0;;
  i) install; exit 0;;
  t) test; exit 0;;
  u) uninstall; exit 0;;
  [?]) echo "i: install; c: clone redmine; t: run tests; u: uninstall";;
  esac
done