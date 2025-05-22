# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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

require File.expand_path('../../test_helper', __FILE__)

# Help controller
class DmsfHelpControllerTest < RedmineDmsf::Test::TestCase
  fixtures :dmsf_folders, :dmsf_files, :dmsf_file_revisions

  def test_wiki_syntax
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf/help/wiki_syntax'
    assert_response :success
    assert_select 'h1', text: 'DMS Syntax Reference'
  end

  def test_wiki_syntax_cs
    @jsmith.language = 'cs'
    assert @jsmith.save
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf/help/wiki_syntax'
    assert_response :success
    assert_select 'h1', text: 'Referenční dokumentace syntaxe DMS'
  end

  def test_dmsf_help
    post '/login', params: { username: 'jsmith', password: 'jsmith' }
    get '/dmsf/help/dmsf_help'
    assert_response :success
    assert_select 'h1', text: "DMSF User's guide"
  end
end
