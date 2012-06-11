module RedmineDmsf
  module Webdav
    class DmsfResource < BaseResource

      def children
        NotFound unless exist? && folder?
        return @children unless @children.nil?
        @children = []
        @_folderdata.subfolders.map do |p|
          @children.push child(p.title, p)
        end
        @_folderdata.files.map do |p|
          @children.push child(p.name, p)
        end
        @children
        
      end

      def exist?
        folder? || file?
      end

      def collection?
        exist? && folder?
      end

      def folder?
        return @_folder unless @_folder.nil?
        @_folder = false
        folders = DmsfFolder.find(:all, :conditions => ["project_id = :project_id", {:project_id => self.Project.id}], :order => "title ASC")
        folders.delete_if {|x| x.title != basename}
        return false unless folders.length > 0
        if (folders.length > 1) then
          folders.delete_if {|x| x.dmsf_path_str != projectless_path}
          return false unless folders.length > 0
          @_folder=true
          @_folderdata = folders[0]
        else
          if ('/'+folders[0].dmsf_path_str == projectless_path) then
            @_folder=true
            @_folderdata = folders[0]
          else
            @_folder= false
          end
        end
        @_folder
      end

      def file?
        return @_file unless @_file.nil?
        @_file = false
        files = DmsfFile.find(:all, :conditions => ["project_id = :project_id AND name = :file_name AND deleted = :deleted", {:project_id => self.Project.id, :file_name => basename, :deleted => false}], :order => "name ASC")
        files.delete_if {|x| File.dirname('/'+x.dmsf_path_str) != File.dirname(projectless_path)}
        if files.length > 0
          @_filedata = files[0]
          @_file = true
        end
      end

      def content_type
        if folder? then
          "inode/directory"
        elsif file?
          @_filedata.last_revision.detect_content_type
        else
          NotFound
        end
      end

      def creation_date
        if folder?
          @_folderdata.created_at
        elsif file?
          @_filedata.created_at
        else
          NotFound
        end
      end

      def last_modified
        if folder?
          @_folderdata.updated_at
        elsif file?
          @_filedata.updated_at
        else
          NotFound
        end
      end

      def etag
        filesize = file? ? @_filedata.size : 4096;
        fileino = file? ? File.stat(@_filedata.last_revision.disk_file).ino : 2;
        sprintf('%x-%x-%x', fileino, filesize, last_modified.to_i)
      end

      def content_length
        file? ? @_filedata.size : 4096;
      end

      def special_type
        l(:field_folder) if folder?
      end

      def get(request, response)
        raise NotFound unless exist?
        if collection?
          html_display
          response['Content-Length'] = response.body.bytesize.to_s
        else
          response.body = download
        end
        OK
      end

      protected 
      def download
        raise NotFound unless file?
        #log_activity("downloaded")
        if @request.env['HTTP_RANGE'].nil?
          access = DmsfFileRevisionAccess.new(:user_id => User.current.id, :dmsf_file_revision_id => @_filedata.last_revision.id,
            :action => DmsfFileRevisionAccess::DownloadAction)
          access.save!
        end

        Download.new(@_filedata.last_revision.disk_file)
        
      end
    end
  end
end


