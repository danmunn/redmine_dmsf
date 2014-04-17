# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2014 Karel Pičman <karel.picman@lbcfree.net>
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

module DmsfLinksHelper    
  
  def folder_tree_options_for_select(folder_tree, options = {})
    s = ''
    folder_tree.each do |name, id|      
      tag_options = {:value => id}
      if id == options[:selected]
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end      
      s << content_tag('option', name, tag_options)
    end
    s.html_safe
  end
  
  # An integer test
  def self.is_a_number?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end   
    
end
