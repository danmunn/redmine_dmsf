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

# Workflows helper
module DmsfWorkflowsHelper
  def render_principals_for_new_dmsf_workflow_users(workflow, dmsf_workflow_step_assignment_id = nil,
                                                    dmsf_file_revision_id = nil)
    scope = workflow.delegates(params[:q], dmsf_workflow_step_assignment_id, dmsf_file_revision_id)
    principal_count = scope.count
    principal_pages = Redmine::Pagination::Paginator.new principal_count, 100, params['page']
    principals = scope.offset(principal_pages.offset).limit(principal_pages.per_page).to_a
    # Delegation
    s = []
    s << if dmsf_workflow_step_assignment_id
           content_tag(
             'div',
             content_tag('div', principals_radio_button_tags('step_action', principals),
                         id: 'dmsf_users_for_delegate'),
             class: 'objects-selection'
           )
         # New step
         else
           content_tag(
             'div',
             content_tag('div', principals_check_box_tags('user_ids[]', principals), id: 'users'),
             class: 'objects-selection'
           )
         end
    links = pagination_links_full(principal_pages, principal_count, per_page_links: false) do |text, parameters, _|
      link_to text,
              autocomplete_for_user_dmsf_workflow_path(workflow, parameters.merge(q: params[:q], format: 'js')),
              remote: true
    end
    s << content_tag('span', links, class: 'pagination')
    safe_join s
  end

  def dmsf_workflow_steps_options_for_select(steps)
    options = [[l(:dmsf_new_step), 0]]
    steps.each do |step|
      options << [step.name.presence || step.step.to_s, step.step]
    end
    options_for_select options, 0
  end

  def dmsf_workflows_for_select(project, dmsf_workflow_id)
    options = [['', -1]]
    DmsfWorkflow.active.sorted.where(['project_id = ? OR project_id IS NULL', project.id]).find_each do |wf|
      options << if wf.project_id
                   [wf.name, wf.id]
                 else
                   ["#{wf.name} #{l(:note_global)}", wf.id]
                 end
    end
    options_for_select options, selected: dmsf_workflow_id
  end

  def dmsf_all_workflows_for_select(dmsf_workflow_id)
    options = [['', 0]]
    DmsfWorkflow.active.sorted.find_each do |wf|
      if wf.project_id
        prj = Project.find_by(id: wf.project_id)
        if User.current.allowed_to?(:manage_workflows, prj)
          # Local approval workflows
          options << if prj
                       ["#{wf.name} (#{prj.name})", wf.id]
                     else
                       [wf.name, wf.id]
                     end
        end
      else
        # Global approval workflows
        options << ["#{wf.name} #{l(:note_global)}", wf.id]
      end
    end
    options_for_select options, selected: dmsf_workflow_id
  end

  def principals_radio_button_tags(name, principals)
    s = []
    principals.each do |principal|
      n = principal.id * 10
      id = "principal_#{n}"
      s << radio_button_tag(name, n, false, onclick: 'noteMandatory(true);', id: id)
      s << content_tag(:label, h(principal), for: id)
      s << tag.br
    end
    safe_join s
  end
end
