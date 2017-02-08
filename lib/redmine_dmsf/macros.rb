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

Redmine::WikiFormatting::Macros.register do

  # dmsf - link to a document
  desc "Wiki link to DMSF file:\n\n" +
           "{{dmsf(file_id [, title [, revision_id]])}}\n\n" +
       "_file_id_ / _revision_id_ can be found in the link for file/revision download."
  macro :dmsf do |obj, args|
    raise ArgumentError if args.length < 1 # Requires file id
    file = DmsfFile.visible.find args[0].strip
    if args[2].blank?
      revision = file.last_revision
    else
      revision = DmsfFileRevision.find(args[2])
      if revision.dmsf_file != file
        raise ActiveRecord::RecordNotFound
      end
    end
    if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
      file_view_url = url_for(:controller => :dmsf_files, :action => 'view', :id => file, :download => args[2])
      return link_to(h(args[1] ? args[1] : file.title),
        file_view_url,
        :target => '_blank',
        :title => h(revision.tooltip),
        'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{file_view_url}")
    else
      raise l(:notice_not_authorized)
    end
  end

  # dmsff - link to a folder
  desc "Wiki link to DMSF folder:\n\n" +
           "{{dmsff(folder_id [, title])}}\n\n" +
       "_folder_id_ may be missing. _folder_id_ can be found in the link for folder opening."
  macro :dmsff do |obj, args|
    if args.length < 1
      return link_to l(:link_documents), dmsf_folder_url(@project)
    else
      folder = DmsfFolder.visible.find args[0].strip
      if User.current && User.current.allowed_to?(:view_dmsf_folders, folder.project)
        return link_to h(args[1] ? args[1] : folder.title),
          dmsf_folder_url(folder.project, :folder_id => folder)
      else
        raise l(:notice_not_authorized)
      end
    end
  end

  # dmsfd - link to the document's details
  desc "Wiki link to DMSF document details:\n\n" +
           "{{dmsfd(document_id)}}\n\n" +
       "_document_id_ can be found in the document's details."
  macro :dmsfd do |obj, args|
    raise ArgumentError if args.length < 1 # Requires file id
    file = DmsfFile.visible.find args[0].strip
    if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
      return link_to file.title, dmsf_file_path(:id => file)
    else
      raise l(:notice_not_authorized)
    end
  end

  # dmsfdesc - link to the document's description
  desc "Wiki link to DMSF document description:\n\n" +
         "{{dmsfdesc(document_id)}}\n\n" +
         "_document_id_ can be found in the document's details."
  macro :dmsfdesc do |obj, args|
    raise ArgumentError if args.length < 1 # Requires file id
    file = DmsfFile.visible.find args[0].strip
    if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
      return textilizable(file.description)
    else
      raise l(:notice_not_authorized)
    end
  end

  # dmsft - link to the document's content preview
  desc "Wiki link to DMSF document's content preview:\n\n" +
           "{{dmsft(file_id)}}\n\n" +
       "_file_id_ can be found in the document's details."
  macro :dmsft do |obj, args|
    raise ArgumentError if args.length < 2 # Requires file id and lines number
    file = DmsfFile.visible.find args[0].strip
    if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
      return file.preview(args[1].strip).gsub("\n", '<br/>').html_safe
    else
      raise l(:notice_not_authorized)
    end
  end

  # dmsf_image - link to an image
  desc "Wiki DMSF image:\n\n" +
             "{{dmsf_image(file_id)}}\n" +
             "{{dmsf_image(file_id, size=300)}} -- with custom title and size\n" +
             "{{dmsf_image(file_id, height=300)}} -- with custom title and height (auto width)\n" +
             "{{dmsf_image(file_id, width=300)}} -- with custom title and width (auto height)\n" +
             "{{dmsf_image(file_id, size=640x480)}}"
  macro :dmsf_image do |obj, args|
    args, options = extract_macro_options(args, :size, :width, :height, :title)
    file_id = args.first
    raise 'DMSF document ID required' unless file_id.present?
    size = options[:size]
    width = options[:width]
    height = options[:height]
    if file = DmsfFile.find_by_id(file_id)
      unless User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
        raise l(:notice_not_authorized)
      end
      raise 'Not supported image format' unless file.image?
      url = url_for(:controller => :dmsf_files, :action => 'view', :id => file)
      if size && size.include?('%')
        image_tag(url, :alt => file.title, :width => size, :height => size)
      elsif height
        image_tag(url, :alt => file.title, :width => 'auto', :height => height)
      elsif width
        image_tag(url, :alt => file.title, :width => width, :height => 'auto')
      else
        image_tag(url, :alt => file.title, :size => size)
      end
    else
      raise "Document ID #{file_id} not found"
    end
  end

  # dmsftn - link to an image thumbnail
  desc "Wiki DMSF thumbnail:\n\n" +
             "{{dmsftn(file_id)}}\n" +
             "{{dmsftn(file_id, size=300)}} -- with custom title and size\n" +
             "{{dmsftn(file_id, height=300)}} -- with custom title and height (auto width)\n" +
             "{{dmsftn(file_id, width=300)}} -- with custom title and width (auto height)\n" +
             "{{dmsftn(file_id, size=640x480)}}"
  macro :dmsftn do |obj, args|
    args, options = extract_macro_options(args, :size, :width, :height, :title)
    file_id = args.first
    raise 'DMSF document ID required' unless file_id.present?
    size = options[:size]
    width = options[:width]
    height = options[:height]
    if file = DmsfFile.find_by_id(file_id)
      unless User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
        raise l(:notice_not_authorized)
      end
      raise 'Not supported image format' unless file.image?
      url = url_for(:controller => :dmsf_files, :action => 'view', :id => file)
      file_view_url = url_for(:controller => :dmsf_files, :action => 'view', :id => file, :download => args[2])
      if size && size.include?("%")
        img = image_tag(url, :alt => file.title, :width => size, :height => size)
      elsif size && size.include?("x")
        img = image_tag(url, :alt => file.title, :size => size)
      elsif height
        img = image_tag(url, :alt => file.title, :width => 'auto', :height => height)
      elsif width
        img = image_tag(url, :alt => file.title, :width => width, :height => 'auto')
      else
        img = image_tag(url, :alt => file.title, :width => 'auto', :height => 200)
      end
      link_to(img,
        file_view_url, :target => '_blank',
        :title => h(file.last_revision.try(:tooltip)),
        'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{file_view_url}")
    else
      raise "Document ID #{file_id} not found"
    end
  end

  # dmsfw - link to a document's approval workflow status
  desc "Wiki link to DMSF document's approval workflow status:\n\n" +
           "{{dmsfw(file_id)}}\n\n" +
       "_file_id_ can be found in the document's details."
  macro :dmsfw do |obj, args|
    raise ArgumentError if args.length < 1 # Requires file id
    file = DmsfFile.visible.find args[0].strip
    if User.current && User.current.allowed_to?(:view_dmsf_files, file.project)
      raise ActiveRecord::RecordNotFound unless file.last_revision
      return file.last_revision.workflow_str(false)
    else
      raise l(:notice_not_authorized)
    end
  end

end