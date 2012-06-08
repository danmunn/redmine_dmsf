module RedmineDmsf
  module Webdav
    class IndexResource < BaseResource

      def children
        projects = Project.visible.find(:all, :order => 'lft')
        return nill if projects.nil? || projects.empty?
        projects.delete_if { |node| node.module_enabled?('dmsf').nil? }
        projects.map do |p|
          child p.identifier
        end
      end

      def collection?
        true
      end

      #Index resource ALWAYS exists
      def exist?
        true
      end

      def get(request, response)
        html_display
        OK
      end
    end
  end
end
