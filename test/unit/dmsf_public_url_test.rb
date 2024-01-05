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

require File.expand_path('../../test_helper', __FILE__)

# Public URL tests
class DmsfPublicUrlsTest < RedmineDmsf::Test::UnitTest
  fixtures :dmsf_public_urls, :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def setup
    super
    @dmsf_public_url1 = DmsfPublicUrl.find 1
  end

  def test_create
    url = DmsfPublicUrl.new
    url.dmsf_file = @file1
    url.user = @jsmith
    url.expire_at = DateTime.current + 1.day
    assert url.save, url.errors.full_messages.to_sentence
    assert_not_nil url.token
  end

  def test_belongs_to_file
    @file1.destroy
    assert_nil DmsfPublicUrl.find_by(id: 1)
  end
end
