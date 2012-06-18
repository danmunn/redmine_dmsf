# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012   Daniel Munn <dan.munn@munnster.co.uk>
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

require 'uuidtools'

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
        return @children unless @children.nil?
        @children = []
        return [] unless collection?
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
      #  - 2012-06-15: Only if you're allowed to browse the project
      #  - 2012-06-18: Issue #5, ensure item is only listed if project is enabled for dmsf
      def exist?
        return false if project.nil? || project.module_enabled?('dmsf').nil? || !(folder? || file?)
        User.current.admin? ? true : User.current.allowed_to?(:view_dmsf_folders, project)
      end

      # is this entity a folder?
      def collection?
        folder? #no need to check if entity exists, as false is returned if entity does not exist anyways
      end

      # Check if current entity is a folder and return DmsfFolder object if found (nil if not)
      # Todo: Move folder data retrieval into folder function, and use folder method to determine existence
      def folder
        return @folder unless @folder == false
        return nil if project.nil? || project.id.nil? #if the project doesnt exist, this entity can't exist
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
        return nil if project.nil? || project.id.nil? #Again if entity project is nil, it cannot exist in context of this object
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

      # Process incoming GET request
      #
      # If instance is a collection, calls html_display (defined in base_resource.rb) which cycles through children for display
      # File will only be presented for download if user has permission to view files
      ##
      def get(request, response)
        raise NotFound unless exist?
        if collection?
          html_display
          response['Content-Length'] = response.body.bytesize.to_s
        else
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:view_dmsf_files, project)
          response.body = download #Rack based provider
        end
        OK
      end

      # Process incoming MKCOL request
      #
      # Create a DmsfFolder at location requested, only if parent is a folder (or root)
      def make_collection
        if (request.body.read.to_s == '')
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:folder_manipulation, project)
          return MethodNotAllowed if exist? #If we already exist, why waste the time trying to save?
          parent_folder = nil
          if (parent.projectless_path != "/")
            return Conflict unless parent.folder?
            parent_folder = parent.folder.id
          end
          f = DmsfFolder.new({:title => basename, :dmsf_folder_id => parent_folder, :description => 'Folder created from WebDav'})
          f.project = project
          f.user = User.current
          f.save ? OK : Conflict
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
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:file_manipulation, project)
          file.delete ? NoContent : Conflict
        elsif (folder?) then
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:folder_manipulation, project)
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

        parent = resource.parent
        if (collection?)

          #At the moment we don't support cross project destinations
          return MethodNotImplemented unless project.id == resource.project.id
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:folder_manipulation, project)

          #Current object is a folder, so now we need to figure out information about Destination
          if(dest.exist?) then

            MethodNotAllowed

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
          raise Forbidden unless User.current.admin? || 
              User.current.allowed_to?(:folder_manipulation, project) || 
              User.current.allowed_to?(:folder_manipulation, resource.project)

          if(dest.exist?) then

            methodNotAllowed 
         
            # Files cannot be merged at this point, until a decision is made on how to merge them
            # ideally, we would merge revision history for both, ensuring the origin file wins with latest revision.
            
          else

            if(parent.projectless_path == "/") #Project root
              f = nil
            else
              return PreconditionFailed unless parent.exist? && parent.folder?
              f = parent.folder
            end
            return PreconditionFailed unless exist? && file?
            return InternalServerError unless file.move_to(resource.project, f)

            #Update Revision and names of file [We can link to old physical resource, as it's not changed]
            rev = file.last_revision
            rev.name = resource.basename
            file.name = resource.basename

            #Save Changes
            (rev.save! && file.save!) ? Created : PreconditionFailed

          end
        end
      end

      # Process incoming COPY request
      #
      # Behavioural differences between collection and single entity
      # Todo: Support overwrite between both types of entity, and an integrative copy where destination exists for collections
      def copy(dest, overwrite)

        # All of this should carry accrross the ResourceProxy frontend, we ensure this to
        # prevent unexpected errors
        if dest.is_a? (ResourceProxy)
          resource = dest.resource
        else
          resource = dest
        end

        return PreconditionFailed if !resource.is_a?(DmsfResource) || resource.project.nil? || resource.project.id == 0
        parent = resource.parent
        if (collection?)

          #Current object is a folder, so now we need to figure out information about Destination
          return MethodNotAllowed if(dest.exist?)

          #Permission check if they can manipulate folders and view folders
          # Can they:
          #  Manipulate folders on destination project :folder_manipulation
          #  View folders on destination project       :view_dmsf_folders
          #  View files on the source project          :view_dmsf_files
          #  View fodlers on the source project        :view_dmsf_folders
          raise Forbidden unless User.current.admin? || 
             (User.current.allowed_to?(:folder_manipulation, resource.project) &&
              User.current.allowed_to?(:view_dmsf_folders, resource.project) &&
              User.current.allowed_to?(:view_dmsf_files, project) &&
              User.current.allowed_to?(:view_dmsf_folders, project))

          return PreconditionFailed if (parent.projectless_path != "/" && !parent.folder?)
          folder.title = resource.basename
          new_folder = folder.copy_to(resource.project, parent.folder)
          return PreconditionFailed if new_folder.nil? || new_folder.id.nil?
          Created
        else
          if(dest.exist?) then

            methodNotAllowed

            # Files cannot be merged at this point, until a decision is made on how to merge them
            # ideally, we would merge revision history for both, ensuring the origin file wins with latest revision.

          else

            #Permission check if they can manipulate folders and view folders
            # Can they:
            #  Manipulate files on destination project   :file_manipulation
            #  View files on destination project         :view_dmsf_files
            #  View files on the source project          :view_dmsf_files
            raise Forbidden unless User.current.admin? ||
               (User.current.allowed_to?(:file_manipulation, resource.project) &&
                User.current.allowed_to?(:view_dmsf_files, resource.project) &&
                User.current.allowed_to?(:view_dmsf_files, project))

            if(parent.projectless_path == "/") #Project root
              f = nil
            else
              return PreconditionFailed unless parent.exist? && parent.folder?
              f = parent.folder
            end
            return PreconditionFailed unless exist? && file?
            return InternalServerError unless file.copy_to(resource.project, f)

            #Update Revision and names of file [We can link to old physical resource, as it's not changed]
            rev = file.last_revision
            rev.name = resource.basename
            file.name = resource.basename

            #Save Changes
            (rev.save! && file.save!) ? Created : PreconditionFailed

          end
        end
      end

      # Lock Check
      # Check for the existance of locks of files (Folders unsupported)
      # At present as deletions of folders are not recursive, we do not need to extend 
      # this to cover every file, just queried
      # TODO: Allow recursive deletions and update lock code appropriately
      def lock_check(lock_scope=nil)
        if file?
          raise Locked if file.locked_for_user?
        end
      end

      # Lock
      # Locks a file entity only (DMSF Folders do not support locking)
      def lock(args)
        return Conflict unless (parent.projectless_path == "/" || parent_exists?) && !collection? && file?
        token = UUIDTools::UUID.md5_create(UUIDTools::UUID_URL_NAMESPACE, projectless_path).to_s
        lock_check(args[:scope])
        if (file.locked? && file.locked_for_user?)
          raise DAV4Rack::LockFailure.new("Failed to lock: #{@path}")
        else
          file.lock unless file.locked?
          @response['Lock-Token'] = token
          Locked
          [8600, token]
        end
      end

      # Unlock
      # Token based unlock (authenticated) will ensure that a correct token is sent, further ensuring
      # ownership of token before permitting unlock
      def unlock(token)
        return NoContent unless file?
        token=token.slice(1, token.length - 2)
        if (token.nil? || token.empty? || User.current.anonymous?)
          BadRequest
        else
          _token = UUIDTools::UUID.md5_create(UUIDTools::UUID_URL_NAMESPACE, projectless_path).to_s
          if (!file.locked? || file.locked_for_user? || token != _token)
            Forbidden
          else
            file.unlock
            NoContent
          end
        end
      end

      # HTTP POST request.
      #
      # Forbidden, as method should not be utilised.
      def post(request, response)
        raise Forbidden
      end

      #
      #
      def put(request, response)
        filename = DmsfHelper.temp_dir+'/'+DmsfHelper.temp_filename(basename).gsub(/[\/\\]/,'')
        raise BadRequest if (collection?)

        raise Forbidden unless User.current.admin? || User.current.allowed_to?(:file_manipulation, project)

        new_revision = DmsfFileRevision.new
        if (exist? && file?) #We're over-writing something, so ultimately a new revision
          f = file
          last_revision = file.last_revision
          new_revision.source_revision = last_revision
          new_revision.major_version = last_revision.major_version
          new_revision.minor_version = last_revision.minor_version
          new_revision.workflow = last_revision.workflow
        else
          raise BadRequest unless ( parent.projectless_path == "/" || (parent.exist? && parent.folder?) )
          f = DmsfFile.new
          f.project = project
          f.name = basename
          f.folder = parent.folder
          f.notification = !Setting.plugin_redmine_dmsf["dmsf_default_notifications"].blank?
          new_revision.minor_version = 0
          new_revision.major_version = 0
        end

        new_revision.project = project
        new_revision.folder = parent.folder
        new_revision.file = f
        new_revision.user = User.current
        new_revision.name = basename
        new_revision.title = DmsfFileRevision.filename_to_title(basename)
        new_revision.description = nil
        new_revision.comment = nil
        new_revision.increase_version(2, true)
        new_revision.mime_type = Redmine::MimeType.of(new_revision.name)
        new_revision.size = request.body.length
        raise InternalServerError unless new_revision.valid? && f.save
        new_revision.disk_filename = new_revision.new_storage_filename

        if new_revision.save
          f.reload
          new_revision.copy_file_content(request.body)
        else
          raise InternalServerError
        end

        Created
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
