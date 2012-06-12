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
        folders = DmsfFolder.find(:all, :conditions => ["project_id = :project_id AND title = :title", {:project_id => self.Project.id, :title => basename}], :order => "title ASC")
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

      def make_collection
        if (request.body.read.to_s == '')

          _folder = false
          if (File.basename(File.dirname(projectless_path)) != "/")
            folders = DmsfFolder.find(:all, :conditions => ["project_id = :project_id AND title = :title", {:project_id => self.Project.id, :title => File.basename(File.dirname(path))}], :order => "title ASC")
            if (folders.length > 1) then
              folders.delete_if {|x| x.dmsf_path_str != File.dirname(projectless_path)}
              return false unless folders.length > 0
              _folder=true
              _folderdata = folders[0]
            elsif (folders.length == 1)
              if ('/'+folders[0].dmsf_path_str == File.dirname(projectless_path)) then
                _folder=true
                _folderdata = folders[0]
              else
                _folder= false
              end
            end
            return MethodNotAllowed unless _folder
            f = DmsfFolder.new({:title => basename, :dmsf_folder_id => _folderdata.id, :description => 'Folder created from WebDav'})
          else
            f = DmsfFolder.new({:title => basename, :dmsf_folder_id => nil, :description => 'Folder created from WebDav'})
          end
          f.project = self.Project
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
        return PreconditionFailed if !dest.Resource.is_a?(DmsfResource) || dest.Resource.Project.nil? || dest.Resource.Project.id == 0
        if (collection?)
          #Current object is a folder, so now we need to figure out information about Destination
          if(dest.exist?) then
            STDOUT.puts "Exist?"
          else
            if(File.basename(File.dirname(dest.Resource.projectless_path)) == "/") #Project root
              if(self.Project.id != dest.Resource.Project.id) then
                return MethodNotImplemented
              end
              folder.dmsf_folder_id = nil
            else
              parent = dest.Resource.parent #Grab parent Resource
              return PreconditionFailed unless parent.exist? && parent.folder?
              folder.dmsf_folder_id = parent.folder.id             
            end
              folder.title = dest.Resource.basename
            folder.save ? Created : PreconditionFailed
          end
        else
          STDOUT.puts "Not a col"
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


