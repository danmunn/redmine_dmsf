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

desc <<~END_DESC
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
  task dmsf_create_digests: :environment do
    m = DmsfCreateDigest.new
    m.dmsf_create_digests
  end
end

# Create digest
class DmsfCreateDigest
  def initialize
    @dry_run = ENV.fetch('dry_run', nil)
    @force_sha256 = ENV.fetch('forceSHA256', nil)
  end

  def dmsf_create_digests
    # Checksum is always the same via WebDAV #1384
    revisions = DmsfFileRevision.where(['digest IS NULL OR digest = ? OR length(digest) < ?',
                                        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
                                        @force_sha256 ? 64 : 32])
    count = revisions.all.size
    n = 0
    revisions.each_with_index do |rev, i|
      if File.exist?(rev.disk_file)
        file = File.new rev.disk_file, 'r'
        if file.respond_to?(:read)
          sha = Digest::SHA256.new
          while (buffer = file.read(8192))
            sha.update buffer
          end
          rev.digest = sha.hexdigest
        else
          rev.digest = Digest::SHA256.file(rev.disk_file)
        end
        rev.save unless @dry_run
      else
        puts "#{rev.disk_file} not found"
      end
      n += 1
      # Progress bar
      print "\r#{i * 100 / count}%"
    end
    print "\r100%\n"
    # Result
    $stdout.puts "#{n}/#{count} revisions updated."
  end
end
