module DmsfWorkflowsHelper
  
  def render_principals_for_new_dmsf_workflow_users(workflow)
    scope = User.active.sorted.like(params[:q])    
    principal_count = scope.count
    principal_pages = Redmine::Pagination::Paginator.new principal_count, 100, params['page']
    principals = scope.offset(principal_pages.offset).limit(principal_pages.per_page).all

    s = content_tag('div', principals_check_box_tags('user_ids[]', principals), :id => 'principals')

    links = pagination_links_full(principal_pages, principal_count, :per_page_links => false) {|text, parameters, options|
      link_to text, autocomplete_for_user_dmsf_workflow_path(workflow, parameters.merge(:q => params[:q], :format => 'js')), :remote => true      
    }

    s + content_tag('p', links, :class => 'pagination')
  end
  
  def dmsf_workflow_steps_options_for_select(steps)
    options = Array.new
    options << [l(:dmsf_new_step), 0]
    steps.each do |step|
      options << [step.to_s, step]
    end
    options_for_select(options, 0)
  end   
  
end
