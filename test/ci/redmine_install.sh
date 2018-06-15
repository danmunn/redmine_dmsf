#!/bin/bash
# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
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

export REDMINE_GIT_REPO=git://github.com/redmine/redmine.git
export REDMINE_GIT_TAG=3.4-stable

clone()
{
  # Exit if the cloning fails
  set -e

  rm -rf $PATH_TO_REDMINE
  git clone -b $REDMINE_GIT_TAG --depth=100 --quiet $REDMINE_GIT_REPO $PATH_TO_REDMINE
}

test()
{
  # Exit if a test fails
  set -e

  cd $PATH_TO_REDMINE

  # create tmp/cache folder (required for Rails 3)
  # https://github.com/rails/rails/issues/5376
  #bundle exec rake tmp:create

  # Run tests within application
  bundle exec rake redmine:plugins:test:units NAME=redmine_dmsf
  bundle exec rake redmine:plugins:test:functionals NAME=redmine_dmsf
  bundle exec rake redmine:plugins:test:integration NAME=redmine_dmsf
}

uninstall()
{
  # Exit if the migration fails
  set -e

  cd $PATH_TO_REDMINE

  # clean up database
  bundle exec rake redmine:plugins:migrate NAME=redmine_dmsf VERSION=0
}

install()
{
  # Exit if the installation fails
  set -e

  # cd to redmine folder
  cd $PATH_TO_REDMINE
  echo current directory is `pwd`

  # Create a link to the dmsf plugin
  ln -sf $PATH_TO_DMSF plugins/redmine_dmsf
  
  # Install gems
  mkdir -p vendor/bundle

  # Copy database.yml
  cp $WORKSPACE/database.yml config/

  # Not ideal, but at present Travis-CI will not install with xapian enabled:
  bundle install --path vendor/bundle --without xapian rmagick development

  # Run Redmine database migrations
  bundle exec rake db:migrate --trace

  # Load Redmine database default data  
  bundle exec rake redmine:load_default_data REDMINE_LANG=en

  # generate session store/secret token
  bundle exec rake generate_secret_token
  
  # Run the plugin database migrations
  bundle exec rake redmine:plugins:migrate
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