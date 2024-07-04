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

# File revision tests
class CustomFieldDmsfFileFormatTest < RedmineDmsf::Test::UnitTest
  fixtures :custom_fields, :projects, :issues, :trackers
  def setup
    super
    User.current = @jsmith
    @issue = Issue.find 1
    @field = IssueCustomField.create!(name: 'DMS Document rev.', field_format: 'dmsf_file_revision')
  end

  def test_possible_values_options
    n = @issue.project.dmsf_files.visible.all.size
    DmsfFolder.visible(false).where(project_id: @issue.project.id).find_each do |f|
      n += f.dmsf_files.visible.all.size
    end
    assert_equal n, @field.possible_values_options(@issue).size
  end

  def test_edit_tag_when_member_not_found
    User.current = User.generate!
    view = ActionView::Base.new(ActionController::Base.view_paths, {}, ActionController::Base.new)
    view.extend(ApplicationHelper)

    begin
      @field.format.edit_tag(view,
                             "issue_custom_field_values_#{@field.id}",
                             "issue[custom_field_values][#{@field.id}]",
                             CustomValue.create!(custom_field: @field, customized: @issue))
      assert true
    rescue NoMethodError => e
      flunk "Test failure: #{e.message}"
    end
  end
end
