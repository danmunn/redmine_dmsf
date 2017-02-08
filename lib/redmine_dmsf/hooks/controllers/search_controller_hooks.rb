# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

module RedmineDmsf
  module Hooks
    include Redmine::Hook
    
    class ControllerSearchHook < RedmineDmsf::Hooks::Listener
                        
      def controller_search_quick_jump(context={})
        if context.is_a?(Hash) 
          question = context[:question]
          if question.present?
            if question.match(/^D(\d+)$/) && DmsfFile.visible.find_by_id($1.to_i)
              return { :controller => 'dmsf_files', :action => 'show', :id => $1.to_i }
            end
          end
        end        
      end      
                  
    end
    
  end
end