module RedmineDmsf
  module Webdav
    class IndexResource < BaseResource

      def initialize(public_path, path, request, response, options)
        super(public_path, path, request, response, options)
      end


      def children
        if @Projects.nil? || @Projects.empty?
          @Projects = Project.visible.find(:all, :order => 'lft')
          @Projects.delete_if { |node| node.module_enabled?('dmsf').nil? }
        end 
        return nil if @Projects.nil? || @Projects.empty?
        @Projects.map do |p|
          child p.identifier
        end
      end

      def collection?
        true
      end

      def creation_date
        Time.now
      end

      def last_modified
        Time.now
      end

      def last_modified=
        MethodNotAllowed
      end

      #Index resource ALWAYS exists
      def exist?
        true
      end

      def etag
        sprintf('%x-%x-%x', children.count, 4096, Time.now.to_i)
      end

      def content_type
        "text/html"
      end

      def content_length
        4096
      end

      def get(request, response)
        html_display
        response['Content-Length'] = response.body.bytesize.to_s
        OK
      end

    end
  end
end
