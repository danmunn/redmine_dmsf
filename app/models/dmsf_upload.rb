# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Pičman <karel.picman@kontron.com>
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

class DmsfUpload
  attr_accessor :name  
  attr_accessor :disk_filename
  attr_reader   :size
  attr_accessor :mime_type
  attr_accessor :title
  attr_accessor :description      
  attr_accessor :comment
  attr_accessor :major_version
  attr_accessor :minor_version
  attr_accessor :locked  
  attr_accessor :workflow
  attr_accessor :custom_values  
  
  def disk_file
    "#{DmsfHelper.temp_dir}/#{self.disk_filename}"
  end    
  
  def self.create_from_uploaded_attachment(project, folder, uploaded_file)    
    a = Attachment.find_by_token(uploaded_file[:token])    
    if a
      uploaded = {
        :disk_filename => DmsfHelper.temp_filename(a.filename),
        :content_type => a.content_type,
        :original_filename => a.filename,
        :comment => uploaded_file[:description]
      }        
      FileUtils.mv(a.diskfile, "#{DmsfHelper.temp_dir}/#{uploaded[:disk_filename]}")
      a.destroy    
      upload = DmsfUpload.new(project, folder, uploaded)
    else
      Rails.logger.error "An attachment not found by its token: #{uploaded_file[:token]}"      
    end
    upload
  end
  
  def initialize(project, folder, uploaded)
    @name = uploaded[:original_filename]
    
    file = DmsfFile.find_file_by_name(project, folder, @name)
    unless file
      link = DmsfLink.find_link_by_file_name(project, folder, @name)
      file = link.target_file if link
    end
    
    @disk_filename = uploaded[:disk_filename]
    @mime_type = uploaded[:content_type]
    @size = File.size(disk_file)    
    
    if file.nil? || file.last_revision.nil?
      @title = DmsfFileRevision.filename_to_title(@name)
      @description = uploaded[:comment]
      @major_version = 0
      @minor_version = 0
      @workflow = nil      
      @custom_values = DmsfFileRevision.new(:file => DmsfFile.new(:project => @project)).custom_field_values      
    else
      last_revision = file.last_revision 
      @title = last_revision.title
      if last_revision.description.present?
        @description = last_revision.description
        @comment = uploaded[:comment] if uploaded[:comment].present?
      elsif uploaded[:comment].present?
        @comment = uploaded[:comment]
      end
      @major_version = last_revision.major_version
      @minor_version = last_revision.minor_version
      @workflow = last_revision.workflow
      @custom_values = Array.new(file.last_revision.custom_values)    

      # Add default value for CFs not existing
      present_custom_fields = file.last_revision.custom_values.collect(&:custom_field).uniq
      file.last_revision.available_custom_fields.each do |cf|
        unless present_custom_fields.include?(cf)
          @custom_values << CustomValue.new({:custom_field => cf, :value => cf.default_value}) if cf.default_value
        end
      end
    end
    
    @locked = file && file.locked_for_user?
  end
  
end