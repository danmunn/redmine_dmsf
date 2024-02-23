# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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
  # Macros
  module Macros
    Redmine::WikiFormatting::Macros.register do
      # dmsf - link to a document
      desc %{Wiki link to DMSF file:
               {{dmsf(file_id [, title [, revision_id]])}}
           _file_id_ / _revision_id_ can be found in the link for file/revision download.}
      macro :dmsf do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsf(#{args[0]})}}" unless file
        unless User.current&.allowed_to?(:view_dmsf_files, file.project, { id: file.id })
          raise ::I18n.t(:notice_not_authorized)
        end

        if args[2].blank?
          revision = file.last_revision
        else
          revision = DmsfFileRevision.find_by(id: args[2], dmsf_file_id: args[0])
          return "{{dmsf(#{args[0]}, #{args[1]}, #{args[2]})}" unless revision
        end
        title = (args[1].presence || file.title)
        title.gsub!(/\A"|"\z/, '') # Remove apostrophes
        title.gsub!(/\A'|'\z/, '')
        title = file.title if title.empty?
        url = view_dmsf_file_url(id: file.id, download: args[2])
        link_to h(title), url,
                target: '_blank',
                rel: 'noopener',
                title: h(revision.tooltip),
                'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{url}"
      end

      # dmsff - link to a folder
      desc %{Wiki link to DMSF folder:
               {{dmsff([folder_id [, title]])}}
           _folder_id_ can be found in the link for folder opening. Without arguments return link to main folder
           'Documents'}
      macro :dmsff do |_obj, args|
        if args.empty?
          unless User.current.allowed_to?(:view_dmsf_folders, @project) && @project.module_enabled?(:dmsf)
            raise ::I18n.t(:notice_not_authorized)
          end

          return link_to ::I18n.t(:link_documents), dmsf_folder_url(@project)
        else
          folder = DmsfFolder.visible.find_by(id: args[0])
          return "{{dmsff(#{args[0]})}}" unless folder
          raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_folders, folder.project)

          title = (args[1].presence || folder.title)
          title.gsub!(/\A"|"\z/, '') # Remove leading and trailing apostrophe
          title.gsub!(/\A'|'\z/, '')
          title = folder.title if title.empty?
          link_to h(title), dmsf_folder_url(folder.project, folder_id: folder)
        end
      end

      # dmsfd - link to the document's details
      desc %{Wiki link to DMSF document details:
               {{dmsfd(document_id [, title])}}
           _document_id_ can be found in the document's details.}
      macro :dmsfd do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsfd(#{args[0]})}}" unless file
        raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)

        title = (args[1].presence || file.title)
        title.gsub!(/\A"|"\z/, '') # Remove leading and trailing apostrophe
        title.gsub!(/\A'|'\z/, '')
        link_to h(title), dmsf_file_path(id: file)
      end

      # dmsfdesc - text referring to the document's description
      desc %{Text referring to DMSF document description:
             {{dmsfdesc(document_id)}}
             _document_id_ can be found in the document's details.}
      macro :dmsfdesc do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsfdesc(#{args[0]})}}" unless file
        raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)

        textilizable file.description
      end

      # dmsfversion - text referring to the document's version
      desc %{Text referring to DMSF document version:
             {{dmsfversion(document_id [, revision_id])}}
             _document_id_ can be found in the document's details.}
      macro :dmsfversion do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsfversion(#{args[0]})}}" unless file
        unless User.current&.allowed_to?(:view_dmsf_files, file.project, { id: file.id })
          raise ::I18n.t(:notice_not_authorized)
        end

        if args[1].blank?
          revision = file.last_revision
        else
          revision = DmsfFileRevision.find_by(id: args[1], dmsf_file_id: args[0])
          return "{{dmsfversion(#{args[0]}, #{args[1]})}}" unless revision
        end
        textilizable revision.version
      end

      # dmsflastupdate - text referring to the document's last update date
      desc %{Text referring to DMSF document last update date:
             {{dmsflastupdate(document_id)}}
             _document_id_ can be found in the document's details.}
      macro :dmsflastupdate do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsflastupdate(#{args[0]})}}" unless file
        raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)

        textilizable format_time(file.last_revision.updated_at)
      end

      # dmsft - link to the document's content preview
      desc %{Text referring to DMSF text document content:
               {{dmsft(file_id, lines_count)}}
           _file_id_ can be found in the document's details. _lines_count_ indicates quantity of lines to show.}
      macro :dmsft do |_obj, args|
        raise ArgumentError if args.length < 2 # Requires file id and lines number

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsft(#{args[0]}, #{args[1]})}}" unless file
        raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)

        content_tag :pre, file.text_preview(args[1])
      end

      # dmsf_image - link to an image
      desc %{Wiki DMSF image:
                 {{dmsf_image(file_id)}}
                 {{dmsf_image(file_id1 file_id2 file_id3)}} -- multiple images
                 {{dmsf_image(file_id, size=50%)}} -- with size 50%
                 {{dmsf_image(file_id, size=300)}} -- with size 300
                 {{dmsf_image(file_id, height=300)}} -- with height (auto width)
                 {{dmsf_image(file_id, width=300)}} -- with width (auto height)
                 {{dmsf_image(file_id, size=640x480)}} -- with size 640x480"}
      macro :dmsf_image do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        args, options = extract_macro_options(args, :size, :width, :height, :title)
        size = options[:size]
        width = options[:width]
        height = options[:height]
        ids = args[0].split
        html = []
        ids.each do |id|
          file = DmsfFile.visible.find_by(id: id)
          unless file
            html << "{{dmsf_image(#{args[0]})}}"
            next
          end
          raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)
          raise ::I18n.t(:error_not_supported_image_format) unless file.image?

          member = Member.find_by(user_id: User.current.id, project_id: file.project.id)
          filename = file.last_revision.formatted_name(member)
          url = static_dmsf_file_url(file, filename: filename)
          html << if size&.include?('%')
                    image_tag url, alt: filename, title: file.title, width: size, height: size
                  elsif height
                    image_tag url, alt: filename, title: file.title, width: 'auto', height: height
                  elsif width
                    image_tag url, alt: filename, title: file.title, width: width, height: 'auto'
                  else
                    image_tag url, alt: filename, title: file.title, size: size
                  end
        end
        safe_join html
      end

      # dmsf_video - link to a video
      desc %{Wiki DMSF video:
               {{dmsf_video(file_id)}}\n" +
               {{dmsf_video(file_id, size=50%)}} -- with size 50%
               {{dmsf_video(file_id, size=300)}} -- with size 300x300
               {{dmsf_video(file_id, height=300)}} -- with height (auto width)
               {{dmsf_video(file_id, width=300)}} -- with width (auto height)
               {{dmsf_video(file_id, size=640x480)}} -- with size 640x480}
      macro :dmsf_video do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        args, options = extract_macro_options(args, :size, :width, :height, :title)
        size = options[:size]
        width = options[:width]
        height = options[:height]
        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsf_video(#{args[0]})}}" unless file
        raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)
        raise ::I18n.t(:error_not_supported_video_format) unless file.video?

        member = Member.find_by(user_id: User.current.id, project_id: file.project.id)
        filename = file.last_revision.formatted_name(member)
        url = static_dmsf_file_url(file, filename: filename)
        if size&.include?('%')
          video_tag url, controls: true, alt: filename, title: file.title, width: size, height: size
        elsif height
          video_tag url, controls: true, alt: filename, title: file.title, width: 'auto', height: height
        elsif width
          video_tag url, controls: true, alt: filename, title: file.title, width: width, height: 'auto'
        else
          video_tag url, controls: true, alt: filename, title: file.title, size: size
        end
      end

      # dmsftn - link to an image thumbnail
      desc %{Wiki DMSF thumbnail:
                 {{dmsftn(file_id)}} -- with default height 200 (auto width)
                 {{dmsftn(file_id1 file_id2 file_id3)}} -- multiple thumbnails
                 {{dmsftn(file_id, size=300)}} -- with size 300x300
                 {{dmsftn(file_id, height=300)}} -- with height (auto width)
                 {{dmsftn(file_id, width=300)}} -- with width (auto height)
                 {{dmsftn(file_id, size=640x480)}} -- with size 640x480}
      macro :dmsftn do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        args, options = extract_macro_options(args, :size, :width, :height, :title)
        size = options[:size]
        width = options[:width]
        height = options[:height]
        ids = args[0].split
        html = []
        ids.each do |id|
          file = DmsfFile.visible.find_by(id: id)
          unless file
            html << "{{dmsftn(#{id})}}"
            next
          end
          raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)
          raise ::I18n.t(:error_not_supported_image_format) unless file.image?

          member = Member.find_by(user_id: User.current.id, project_id: file.project.id)
          filename = file.last_revision.formatted_name(member)
          url = static_dmsf_file_url(file, filename: filename)
          img = if size
                  image_tag(url, alt: filename, title: file.title, size: size)
                elsif height
                  image_tag(url, alt: filename, title: file.title, width: 'auto', height: height)
                elsif width
                  image_tag(url, alt: filename, title: file.title, width: width, height: 'auto')
                else
                  image_tag(url, alt: filename, title: file.title, width: 'auto', height: 200)
                end
          html << link_to(img, url,
                          target: '_blank',
                          rel: 'noopener',
                          title: h(file.last_revision.try(:tooltip)),
                          'data-downloadurl' => "#{file.last_revision.detect_content_type}:#{h(file.name)}:#{url}")
        end
        safe_join html
      end

      # dmsfw - link to a document's approval workflow status
      desc %{Text referring to DMSF document's approval workflow status:
               {{dmsfw(file_id)}}
           _file_id_ can be found in the document's details.}
      macro :dmsfw do |_obj, args|
        raise ArgumentError if args.empty? # Requires file id

        file = DmsfFile.visible.find_by(id: args[0])
        return "{{dmsfw(#{args[0]})}}" unless file
        raise ::I18n.t(:notice_not_authorized) unless User.current&.allowed_to?(:view_dmsf_files, file.project)

        file.last_revision.workflow_str(false)
      end
    end
  end
end
