module RedmineDmsf
  module Webdav
    class ProjectResource < BaseResource

      def initialize(public_path, path, request, response, options)
        super(public_path, path, request, response, options)
      end

      def children
        #caching for repeat usage
        return @children unless @children.nil?
        @children = []
        DmsfFolder.project_root_folders(self.Project).map do |p|
          @children.push child(p.title, p)
        end
        DmsfFile.project_root_files(self.Project).map do |p|
          @children.push child(p.name, p)
        end
        @children
      end

      def exist?
        !(self.Project.nil? || User.current.anonymous?)
      end

      def collection?
        exist?
      end

      def creation_date
        self.Project.created_on unless self.Project.nil?
      end

      def last_modified
        self.Project.updated_on unless self.Project.nil?
      end

      def etag
        sprintf('%x-%x-%x', 0, 4096, last_modified.to_i)
      end

      def name
        self.Project.identifier unless self.Project.nil?
      end

      def long_name
        self.Project.name unless self.Project.nil?
      end

      def content_type
        "inode/directory" #l(:field_project)
      end

      def special_type
        l(:field_project)
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
