# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011   Vít Jonáš <vit.jonas@gmail.com>
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.%>

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
