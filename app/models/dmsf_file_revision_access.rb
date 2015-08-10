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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class DmsfFileRevisionAccess < ActiveRecord::Base
  unloadable
  belongs_to :revision, :class_name => 'DmsfFileRevision', :foreign_key => 'dmsf_file_revision_id'
  belongs_to :user
  delegate :project, :to => :revision, :allow_nil => false
  delegate :file, :to => :revision, :allow_nil => false  
  accepts_nested_attributes_for :user, :revision  

  DownloadAction = 0
  EmailAction = 1

  acts_as_event :title => Proc.new {|o| "#{l(:label_dmsf_downloaded)}: #{o.file.dmsf_path_str}"},
    :url => Proc.new {|o| {:controller => 'dmsf_files', :action => 'show', :id => o.file}},
    :datetime => Proc.new {|o| o.updated_at },
    :description => Proc.new {|o| o.revision.comment },
    :author => Proc.new {|o| o.user }    
 
  acts_as_activity_provider :type => 'dmsf_file_revision_accesses',
    :timestamp => "#{DmsfFileRevisionAccess.table_name}.updated_at",
    :author_key => "#{DmsfFileRevisionAccess.table_name}.user_id",
    :permission => :view_dmsf_file_revision_accesses,
    :scope => select("#{DmsfFileRevisionAccess.table_name}.*").
      joins(
        "INNER JOIN #{DmsfFileRevision.table_name} ON #{DmsfFileRevisionAccess.table_name}.dmsf_file_revision_id = #{DmsfFileRevision.table_name}.id " +
        "INNER JOIN #{DmsfFile.table_name} ON #{DmsfFileRevision.table_name}.dmsf_file_id = #{DmsfFile.table_name}.id " +
        "INNER JOIN #{Project.table_name} ON #{DmsfFile.table_name}.project_id = #{Project.table_name}.id").
      where("#{DmsfFile.table_name}.deleted = :false", {:false => false}) 

end
