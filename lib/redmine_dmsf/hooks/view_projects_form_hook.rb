module RedmineDmsf
  module Hooks
    class ViewProjectsFormHook < Redmine::Hook::ViewListener
      include Redmine::I18n

      def view_projects_form(context={})
        context[:controller].send(:render_to_string, {
          :partial => "hooks/redmine_dmsf/view_projects_form",
          :locals => context
        })

      end

    end
  end
end
