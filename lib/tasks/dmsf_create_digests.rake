# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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

desc <<-END_DESC
DMSF maintenance task
  * Create missing checksums for all file revisions

Available options:
  *dry_run - test, no changes to the database
  *forceSHA256 - replace old MD5 with SHA256

Example:
  bundle exec rake redmine:dmsf_create_digests RAILS_ENV="production"
  bundle exec rake redmine:dmsf_create_digests forceSHA256=1 RAILS_ENV="production"
  bundle exec rake redmine:dmsf_create_digests dry_run=1 RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :dmsf_create_digests => :environment do
    m = DmsfDigest.new
    m.create_digests
  end
end

class DmsfDigest

  def initialize
    @dry_run = ENV['dry_run']
    @force_sha256 = ENV['forceSHA256']
  end

  def create_digests
    revisions = DmsfFileRevision.where(['digest IS NULL OR length(digest) < ?', @force_sha256 ? 64 : 32]).all
    count = revisions.count
    n = 0
    revisions.each_with_index do |rev, i|
      rev.create_digest
      rev.save unless @dry_run
      n += 1
      # Progress bar
      print "\r#{i * 100 / count}%"
    end
    print "\r100%\n"
    # Result
    puts "#{n}/#{DmsfFileRevision.count} revisions updated."
  end

end
