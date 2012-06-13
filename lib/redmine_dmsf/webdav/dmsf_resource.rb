module RedmineDmsf
  module Webdav
    class DmsfResource < BaseResource

      def initialize(*args)
        super(*args)
        @file = false
        @folder = false
      end


      # Gather collection of objects that denote current entities child entities
      # Used for listing directories etc, implemented basic caching because otherwise
      # Our already quite heavy usage of DB would just get silly every time we called
      # this method.
      def children
        MethodNotAllowed unless collection?
        return @children unless @children.nil?
        @children = []
        folder.subfolders.map do |p|
          @children.push child(p.title, p)
        end
        folder.files.map do |p|
          @children.push child(p.name, p)
        end
        @children        
      end

      # Does the object exist?
      # If it is either a folder or a file, then it exists
      def exist?
        folder? || file?
      end

      # is this entity a folder?
      def collection?
        folder? #no need to check if entity exists, as false is returned if entity does not exist anyways
      end

      # Check if current entity is a folder and return DmsfFolder object if found (nil if not)
      # Todo: Move folder data retrieval into folder function, and use folder method to determine existence
      def folder
        return @folder unless @folder == false
        @folder = nil
        # Note: Folder is searched for as a generic search to prevent SQL queries being generated:
        # if we were to look within parent, we'd have to go all the way up the chain as part of the 
        # existence check, and although I'm sure we'd love to access the heirarchy, I can't yet
        # see a practical need for it
        folders = DmsfFolder.find(:all, :conditions => ["project_id = :project_id AND title = :title", {:project_id => project.id, :title => basename}], :order => "title ASC")
        return nil unless folders.length > 0
        if (folders.length > 1) then
          folders.delete_if {|x| '/'+x.dmsf_path_str != projectless_path}
          return nil unless folders.length > 0
          @folder = folders[0]
        else
          if ('/'+folders[0].dmsf_path_str == projectless_path) then
            @folder = folders[0]
          end
        end
        @folder
      end

      # return boolean to determine if entity is a folder or not
      def folder?
        return !folder.nil?
      end

      # Check if current entity exists as a file (DmsfFile), and returns corresponding object if found (nil otherwise)
      # Currently has a dual search approach (depending on if parent can be determined)
      # Todo: Move file data retrieval into folder function, and use file method to determine existence
      def file
        return @file unless @file == false
        @file = nil

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
          @file = DmsfFile.find_file_by_name(project, f, basename)
        else
          # If folder is false, means it couldn't pick up parent, 
          # as such its probably fine to bail out, however we'll 
          # perform a search in this scenario
          files = DmsfFile.find(:all, :conditions => ["project_id = :project_id AND name = :file_name AND deleted = :deleted", {:project_id => project.id, :file_name => basename, :deleted => false}], :order => "name ASC")
          files.delete_if {|x| File.dirname('/'+x.dmsf_path_str) != File.dirname(projectless_path)}
          if files.length > 0
            @file = files[0]
          end
        end
      end

      # return boolean to determine if entity is a file or not
      def file?
        return !file.nil?
      end

      # Return the content type of file
      # will return inode/directory for any collections, and appropriate for File entities
      def content_type
        if folder? then
          "inode/directory"
        elsif file?
          file.last_revision.detect_content_type
        else
          NotFound
        end
      end

      def creation_date
        if folder?
          folder.created_at
        elsif file?
          file.created_at
        else
          NotFound
        end
      end

      def last_modified
        if folder?
          folder.updated_at
        elsif file?
          file.updated_at
        else
          NotFound
        end
      end

      def etag
        filesize = file? ? file.size : 4096;
        fileino = file? ? File.stat(file.last_revision.disk_file).ino : 2;
        sprintf('%x-%x-%x', fileino, filesize, last_modified.to_i)
      end

      def content_length
        file? ? file.size : 4096;
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
          response.body = download #Rack based provider
        end
        OK
      end

      # Process incoming MKCOL request
      #
      # Create a DmsfFolder at location requested, only if parent is a folder (or root)
      def make_collection
        if (request.body.read.to_s == '')
          return MethodNotAllowed if exist? #If we already exist, why waste the time trying to save?
          parent_folder = nil
          if (parent.projectless_path != "/")
            return MethodNotAllowed unless parent.folder?
            parent_folder = parent.folder.id
          end
          f = DmsfFolder.new({:title => basename, :dmsf_folder_id => parent_folder, :description => 'Folder created from WebDav'})
          f.project = project
          f.user = User.current
          f.save ? OK : MethodNotAllowed
        else
          UnsupportedMediaType
        end
      end

      # Process incoming DELETE request
      #
      # <instance> should be of entity to be deleted, we simply follow the Dmsf entity method
      # for deletion and return of appropriate status based on outcome.
      def delete
        if(file?) then
          file.delete ? NoContent : Conflict
        elsif (folder?) then
          folder.delete ? NoContent : Conflict
        else
          MethodNotAllowed
        end
      end

      # Process incoming MOVE request
      #
      # Behavioural differences between collection and single entity
      # Todo: Support overwrite between both types of entity, and implement better checking
      def move(dest, overwrite)

        # All of this should carry accrross the ResourceProxy frontend, we ensure this to
        # prevent unexpected errors
        if dest.is_a? (ResourceProxy)
          resource = dest.resource
        else
          resource = dest
        end

        return PreconditionFailed if !resource.is_a?(DmsfResource) || resource.project.nil? || resource.project.id == 0

        #At the moment we don't support cross project destinations
        return MethodNotImplemented unless project.id == resource.project.id

        parent = resource.parent
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
              folder.title = resource.basename
            folder.save ? Created : PreconditionFailed

          end
        else
          if(dest.exist?) then
            
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
            rev.name = resource.basename
            file.name = resource.basename

            #Save Changes
            (rev.save! && file.save!) ? Created : PreconditionFailed

          end
        end
      end

      private
      # Prepare file for download using Rack functionality:
      # Download (see RedmineDmsf::Webdav::Download) extends Rack::File to allow single-file 
      # implementation of service for request, which allows for us to pipe a single file through
      # also best-utilising DAV4Rack's implementation.
      def download
        raise NotFound unless file?

        # If there is no range (start of ranged download, or direct download) then we log the
        # file access, so we can properly keep logged information
        if @request.env['HTTP_RANGE'].nil?
          access = DmsfFileRevisionAccess.new(:user_id => User.current.id, :dmsf_file_revision_id => file.last_revision.id,
            :action => DmsfFileRevisionAccess::DownloadAction)
          access.save!
        end
        Download.new(file.last_revision.disk_file)
      end
    end
  end
end
