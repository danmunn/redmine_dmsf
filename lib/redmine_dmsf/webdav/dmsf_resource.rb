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
        folders = DmsfFolder.find(:all, :conditions => ["project_id = :project_id AND title = :title", {:project_id => project.id, :title => basename}], :order => "title ASC")
        return false unless folders.length > 0
        if (folders.length > 1) then
          folders.delete_if {|x| '/'+x.dmsf_path_str != projectless_path}
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

        #
        # Hunt for files parent path
        f = false
        if (parent.projectless_path != "/")
          if parent.folder?
            f = parent.folder
          end
        else
          f = nil
        end

        if f || f.nil? then
          # f has a value other than false? - lets use traditional
          # DMSF file search by name.
          @_filedata = DmsfFile.find_file_by_name(project, f, basename)
          @_file = !@_filedata.nil?
        else
          # If folder is false, means it couldn't pick up parent, 
          # as such its probably fine to bail out, however we'll 
          # perform a search in this scenario
          files = DmsfFile.find(:all, :conditions => ["project_id = :project_id AND name = :file_name AND deleted = :deleted", {:project_id => project.id, :file_name => basename, :deleted => false}], :order => "name ASC")
          files.delete_if {|x| File.dirname('/'+x.dmsf_path_str) != File.dirname(projectless_path)}
          if files.length > 0
            @_filedata = files[0]
            @_file = true
          end
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

      def make_collection
        if (request.body.read.to_s == '')

          _folder = false
          _folderid = nil
          if (parent.projectless_path != "/")
            if parent.folder? then
              _folderdata = parent.folder
              _folder = true
            end
            return MethodNotAllowed unless _folder
            _folderid = _folderdata.id
          end
          f = DmsfFolder.new({:title => basename, :dmsf_folder_id => _folderid, :description => 'Folder created from WebDav'})
          f.project = project
          f.user = User.current
          f.save ? OK : MethodNotAllowed
        else
          UnsupportedMediaType
        end
      end

      def delete
        if(file?) then
          @_filedata.delete ? NoContent : Conflict
        elsif (folder?) then
          @_folderdata.delete ? NoContent : Conflict
        else
          NotFound
        end
      end

      def move(dest, overwrite)
        return PreconditionFailed if !dest.Resource.is_a?(DmsfResource) || dest.Resource.project.nil? || dest.Resource.project.id == 0

        #At the moment we don't support cross project destinations
        return MethodNotImplemented unless project.id == dest.Resource.project.id

        parent = dest.Resource.parent
        if (collection?)
          #Current object is a folder, so now we need to figure out information about Destination
          if(dest.exist?) then
            STDOUT.puts "Exist?"
          else

            if(parent.projectless_path == "/") #Project root
              folder.dmsf_folder_id = nil
            else
              return PreconditionFailed unless parent.exist? && parent.folder?
              folder.dmsf_folder_id = parent.folder.id             
            end
              folder.title = dest.Resource.basename
            folder.save ? Created : PreconditionFailed

          end
        else
          if(dest.exist?) then
            STDOUT.puts "Exist?"
          else

            if(parent.projectless_path == "/") #Project root
              f = nil
            else
              return PreconditionFailed unless parent.exist? && parent.folder?
              f = parent.folder
            end
            return PreconditionFailed unless exist? && file?
            return InternalServerError unless file.move_to(project, f)

            #Update Revision and names of file [We can link to old physical resource, as it's not changed]
            rev = file.last_revision
            rev.name = dest.Resource.basename
            file.name = dest.Resource.basename

            #Save Changes
            (rev.save! && file.save!) ? Created : PreconditionFailed

          end
        end
      end


      def folder
        return @_folderdata if folder?
      end

      def file
        return @_filedata if file?
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


