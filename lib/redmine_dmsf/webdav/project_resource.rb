module RedmineDmsf
  module Webdav
    class ProjectResource < BaseResource

      def name
        @project.name
      end

      def exist?
        !@Project.nil?
      end

      def collection?
        exist?
      end

      def last_modified
        @project.updated_on unless @project.nil?
      end

      def name
        @project.identifier unless @project.nil?
      end

      def long_name
        @project.name unless @project.nil?
      end

      def content_type
        "Project" #l(:field_project)
      end

    end
  end
end
