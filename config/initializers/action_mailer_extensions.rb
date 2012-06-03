module ActionMailer
  class Base
    class_inheritable_accessor :view_paths
    
    def self.prepend_view_path(path)
      view_paths.unshift(*path)
      ActionView::TemplateFinder.process_view_paths(path)
    end

    def self.append_view_path(path)
      view_paths.push(*path)
      ActionView::TemplateFinder.process_view_paths(path)
    end

    private
    def self.view_paths
      @@view_paths ||= [template_root]
    end
    
    def view_paths
      self.class.view_paths
    end
    
    def initialize_template_class(assigns)
      ActionView::Base.new(view_paths, assigns, self)
    end

  end
end
