# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
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

class DmsfFileRevisionAccess < ActiveRecord::Base

  unloadable
  belongs_to :dmsf_file_revision
  belongs_to :user
  delegate :dmsf_file, :to => :dmsf_file_revision, :allow_nil => false
  delegate :project, :to => :dmsf_file, :allow_nil => false

  DownloadAction = 0.freeze
  EmailAction = 1.freeze

  acts_as_event :title => Proc.new {|ra| "#{l(:label_dmsf_downloaded)}: #{ra.dmsf_file.dmsf_path_str}"},
    :url => Proc.new {|ra| {:controller => 'dmsf_files', :action => 'show', :id => ra.dmsf_file}},
    :datetime => Proc.new {|ra| ra.updated_at },
    :description => Proc.new {|ra| ra.dmsf_file_revision.comment },
    :author => Proc.new {|ra| ra.user }

  acts_as_activity_provider :type => 'dmsf_file_revision_accesses',
    :timestamp => "#{DmsfFileRevisionAccess.table_name}.updated_at",
    :author_key => "#{DmsfFileRevisionAccess.table_name}.user_id",
    :permission => :view_dmsf_file_revision_accesses,
    :scope => DmsfFileRevisionAccess.
      joins(:dmsf_file_revision).joins("JOIN #{DmsfFile.table_name} ON dmsf_files.id = dmsf_file_revisions.dmsf_file_id").
      joins("JOIN #{Project.table_name} on dmsf_files.project_id = projects.id").
      where(:dmsf_files => { :deleted => DmsfFile::STATUS_ACTIVE })
end
