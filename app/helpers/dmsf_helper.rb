module DmsfHelper

  # TODO: Complete function
  # Return a pre-rendered line item for the current items parent (where feasible)
  #
  # * *Args*    :
  #   - +parent+ -> parent item (Dmsf::Folder entity or nil)
  # * *Returns* :
  #   - +String+ -> HTML Representation of parent link
  #
  def render_parent_link(parent)
    return ''
  end

  def render_dmsf_entity_list
  end

  def dmsf_stylesheet_link_tags(args = nil)
    args ||= {}
    default_args = {:controller => true, :global => false}
    args = default_args.merge(args)
    _return = ''

    if args[:global]
      _return << stylesheet_link_tag('dmsf', :media => "all", :plugin => "redmine_dmsf")
    end

    if !params[:controller].blank? && args[:controller]
      begin
        _return << stylesheet_link_tag('dmsf_' + params[:controller].downcase, :media => "all", :plugin => "redmine_dmsf")
      rescue Exception => e
        e.message
      end
    end
    return _return.html_safe
  end
end