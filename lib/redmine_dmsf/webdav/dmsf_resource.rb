# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-19 Karel Pičman <karel.picman@kontron.com>
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
require 'addressable/uri'

module RedmineDmsf
  module Webdav
    class DmsfResource < BaseResource
      include Redmine::I18n

      def initialize(path, request, response, options)
        @folder = nil
        @file = nil
        super(path, request, response, options)
      end

      # Here we make sure our folder and file methods are not aliased - it should shave a few cycles off of processing
      def setup
        @skip_alias |= [ :folder, :file ]
      end

      # Gather collection of objects that denote current entities child entities
      # Used for listing directories etc, implemented basic caching because otherwise
      # Our already quite heavy usage of DB would just get silly every time we called
      # this method.
      def children
        unless @children
          @children = []
          if collection?
            folder.dmsf_folders.visible.pluck(:title).each do |title|
              @children.push child(title)
            end
            folder.dmsf_files.visible.pluck(:name).each do |name|
              @children.push child(name)
            end
          end
        end
        @children
      end

      # Does the object exist?
      # If it is either a folder or a file, then it exists
      def exist?
        project && project.module_enabled?('dmsf') && (folder || file) &&
          (User.current.admin? || User.current.allowed_to?(:view_dmsf_folders, project))
      end

      def really_exist?
        project && project.module_enabled?('dmsf') && (folder || file)
      end

      # Is this entity a folder?
      def collection?
        folder.present? # No need to check if entity exists, as false is returned if entity does not exist anyways
      end

      # Check if current entity is a folder and return DmsfFolder object if found (nil if not)
      def folder
        unless @folder
          return nil unless project
          @folder = DmsfFolder.visible.where(:project_id => project.id, :title => basename,
            :dmsf_folder_id => parent.folder ? parent.folder.id : nil).first
        end
        @folder
      end

      # Check if the current entity exists as a file (DmsfFile), and returns corresponding object if found (nil otherwise)
      def file
        unless @file
          return nil unless project # Again if entity project is nil, it cannot exist in context of this object
          @file = DmsfFile.find_file_by_name(project, parent.folder, basename)
        end
        @file
      end

      # Return the content type of file
      # will return inode/directory for any collections, and appropriate for File entities
      def content_type
        if folder
          'inode/directory'
        elsif file && file.last_revision
          file.last_revision.detect_content_type
        else
          NotFound
        end
      end

      def creation_date
        if folder
          folder.created_at
        elsif file
          file.created_at
        else
          NotFound
        end
      end

      def last_modified
        if folder
          folder.updated_at
        elsif file && file.last_revision
          file.last_revision.updated_at
        else
          NotFound
        end
      end

      def etag
        filesize = file ? file.size : 4096
        fileino = (file && file.last_revision && File.exist?(file.last_revision.disk_file)) ? File.stat(file.last_revision.disk_file).ino : 2
        sprintf('%x-%x-%x', fileino, filesize, last_modified.to_i)
      end

      def content_length
        file ? file.size : 4096;
      end

      def special_type
        l(:field_folder) if folder
      end

      # Process incoming GET request
      #
      # If instance is a collection, calls html_display (defined in base_resource.rb) which cycles through children for display
      # File will only be presented for download if user has permission to view files
      def get(request, response)
        raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder))
        if collection?
          html_display
          response['Content-Length'] = response.body.bytesize.to_s
        else
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:view_dmsf_files, project)
          response.body = download # Rack based provider
        end
        OK
      end

      # Process incoming MKCOL request
      #
      # Create a DmsfFolder at location requested, only if parent is a folder (or root)
      # - 2012-06-18: Ensure item is only functional if project is enabled for dmsf
      def make_collection
        if request.body.read.to_s.empty?
          raise NotFound unless project && project.module_enabled?('dmsf')
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:folder_manipulation, project)
          raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder, false))
          return MethodNotAllowed if exist? # If we already exist, why waste the time trying to save?
          parent_folder = nil
          if parent.projectless_path != '/'
            return Conflict unless parent.folder
            parent_folder = parent.folder.id
          end
          f = DmsfFolder.new
          f.title = basename
          f.dmsf_folder_id = parent_folder
          f.project = project
          f.user = User.current
          f.save ? Created : Conflict
        else
          UnsupportedMediaType
        end
      end

      # Process incoming DELETE request
      #
      # <instance> should be of entity to be deleted, we simply follow the Dmsf entity method
      # for deletion and return of appropriate status based on outcome.
      def delete
        if file
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:file_delete, project)
          raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder, false))
          pattern = Setting.plugin_redmine_dmsf['dmsf_webdav_disable_versioning']
          if pattern.present? && basename.match(pattern)
            # Files that are not versioned should be destroyed
            destroy = true
          elsif file.last_revision.size == 0
            # Zero-sized files should be destroyed
            destroy = true
          else
            destroy = false
          end
          if file.delete(destroy)
            DmsfMailer.deliver_files_deleted(project, [file])
            NoContent
          else
            Conflict
          end
        elsif folder
          # To fullfil Litmus requirements to not delete folder if fragments are in the URL
          uri = URI(request.get_header('REQUEST_URI'))
          raise BadRequest if uri.fragment
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:folder_manipulation, project)
          raise Forbidden unless DmsfFolder.permissions?(folder, false)
          folder.delete(false) ? NoContent : Conflict
        else
          MethodNotAllowed
        end
      end

      # Process incoming MOVE request
      #
      # Behavioural differences between collection and single entity
      # TODO: Support overwrite between both types of entity, and implement better checking
      def move(dest, overwrite)
        dest = @__proxy.class.new(dest, @request, @response, @options.merge(:user => @user))
        # All of this should carry across the ResourceProxy frontend, we ensure this to
        # prevent unexpected errors
        resource = dest.is_a?(ResourceProxy) ? dest.resource : dest
        return PreconditionFailed if !resource.is_a?(DmsfResource) || resource.project.nil?
        parent = resource.parent
        raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder, false))

        if collection?

          if dest.exist?
            return overwrite ? NotImplemented : PreconditionFailed
          end

          # At the moment we don't support cross project destinations
          return NotImplemented unless (project.id == resource.project.id)
          raise Forbidden unless User.current.admin? || User.current.allowed_to?(:folder_manipulation, project)
          raise Forbidden unless DmsfFolder.permissions?(folder, false)

          # Current object is a folder, so now we need to figure out information about Destination
          if dest.exist?
            return overwrite ? NotImplemented : PreconditionFailed
          else
            if parent.projectless_path == '/' # Project root
              folder.dmsf_folder_id = nil
            else
              return PreconditionFailed unless parent.exist? && parent.folder
                folder.dmsf_folder_id = parent.folder.id
            end
            folder.title = resource.basename
            folder.save ? Created : PreconditionFailed
          end
        else
          raise Forbidden unless User.current.admin? ||
              User.current.allowed_to?(:folder_manipulation, project) ||
              User.current.allowed_to?(:folder_manipulation, resource.project)

          if dest.exist?
            return PreconditionFailed unless overwrite
            if (project == resource.project) && file.name.match(/.\.tmp$/i)
              # Renaming a *.tmp file to an existing file in the same project, probably Office that is saving a file.
              Rails.logger.info "WebDAV MOVE: #{file.name} -> #{resource.basename} (exists), possible MSOffice rename from .tmp when saving"
              
              if resource.file.last_revision.size == 0 || reuse_version_for_locked_file(resource.file)
                # Last revision in the destination has zero size so reuse that revision
                new_revision = resource.file.last_revision
              else
                # Create a new revison by cloning the last revision in the destination
                new_revision = resource.file.last_revision.clone
                new_revision.increase_version(1)
              end

              # The file on disk must be renamed from .tmp to the correct filetype or else Xapian won't know how to index.
              # Copy file.last_revision.disk_file to new_revision.disk_file
              new_revision.size = file.last_revision.size
              new_revision.disk_filename = new_revision.new_storage_filename
              Rails.logger.info "WebDAV MOVE: Copy file #{file.last_revision.disk_filename} -> #{new_revision.disk_filename}"
              File.open(file.last_revision.disk_file, 'rb') do |f|
                new_revision.copy_file_content(f)
              end

              # Save
              new_revision.save && resource.file.save

              # Delete (and destroy) the file that should have been renamed and return what should have been returned in case of a copy
              file.delete(true) ? Created : PreconditionFailed
            else
              # Files cannot be merged at this point, until a decision is made on how to merge them
              # ideally, we would merge revision history for both, ensuring the origin file wins with latest revision.
              NotImplemented
            end
          else
            if parent.projectless_path == '/' # Project root
              f = nil
            else
              return PreconditionFailed unless parent.exist? && parent.folder
              f = parent.folder
            end
            return PreconditionFailed unless exist? && file
            
            if (project == resource.project) && resource.basename.match(/.\.tmp$/i)
              Rails.logger.info "WebDAV MOVE: #{file.name} -> #{resource.basename}, possible MSOffice rename to .tmp when saving."
              # Renaming the file to X.tmp, might be Office that is saving a file. Keep the original file.
              file.copy_to_filename(resource.project, f, resource.basename)
              Created
            else
              if (project == resource.project) && (file.last_revision.size == 0)
                # Moving a zero sized file within the same project, just update the dmsf_folder
                file.dmsf_folder = f
              else
                return InternalServerError unless file.move_to(resource.project, f)
              end

              # Update Revision and names of file [We can link to old physical resource, as it's not changed]
              if file.last_revision
                file.last_revision.name = resource.basename
                file.last_revision.title = DmsfFileRevision.filename_to_title(resource.basename)
              end
              file.name = resource.basename

              # Save Changes
              (file.last_revision.save && file.save) ? Created : PreconditionFailed
            end
          end
        end
      end

      # Process incoming COPY request
      #
      # Behavioural differences between collection and single entity
      # TODO: Support overwrite between both types of entity, and an integrative copy where destination exists for collections
      def copy(dest, overwrite, depth)
        dest = @__proxy.class.new(dest, @request, @response, @options.merge(:user => @user))
        # All of this should carry across the ResourceProxy frontend, we ensure this to
        # prevent unexpected errors
        if dest.is_a?(ResourceProxy)
          resource = dest.resource
        else
          resource = dest
        end

        return PreconditionFailed if !resource.is_a?(DmsfResource) || resource.project.nil?

        parent = resource.parent
        raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder, false))

        if dest.exist?
          return overwrite ? NotImplemented : PreconditionFailed
        end

        return Conflict unless dest.parent.exist?

        if collection?
          # Permission check if they can manipulate folders and view folders
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
          raise Forbidden unless DmsfFolder.permissions?(folder, false)

          return PreconditionFailed if (parent.projectless_path != '/' && !parent.folder)
          folder.title = resource.basename
          new_folder = folder.copy_to(resource.project, parent.folder)
          return PreconditionFailed if new_folder.nil? || new_folder.id.nil?
          Created
        else
          # Permission check if they can manipulate folders and view folders
          # Can they:
          #  Manipulate files on destination project   :file_manipulation
          #  View files on destination project         :view_dmsf_files
          #  View files on the source project          :view_dmsf_files
          raise Forbidden unless User.current.admin? ||
             (User.current.allowed_to?(:file_manipulation, resource.project) &&
              User.current.allowed_to?(:view_dmsf_files, resource.project) &&
              User.current.allowed_to?(:view_dmsf_files, project))

          if parent.projectless_path == '/' # Project root
            f = nil
          else
            return PreconditionFailed unless parent.exist? && parent.folder
            f = parent.folder
          end
          return PreconditionFailed unless exist? && file
          new_file = file.copy_to(resource.project, f)
          return InternalServerError unless (new_file && new_file.last_revision)

          # Update Revision and names of file [We can link to old physical resource, as it's not changed]
          new_file.last_revision.name = resource.basename
          new_file.name = resource.basename

          # Save Changes
          (new_file.last_revision.save && new_file.save) ? Created : PreconditionFailed
        end
      end

      # Lock Check
      # Check for the existence of locks
      # At present as deletions of folders are not recursive, we do not need to extend
      # this to cover every file, just queried
      def lock_check(lock_scope = nil)
        if file
          raise Locked if file.locked_for_user?
        elsif folder
          raise Locked if folder.locked_for_user?
        end
      end

      # Lock
      def lock(args)
        unless (parent.projectless_path == '/') || parent_exists?
          e = DAV4Rack::LockFailure.new
          e.add_failure @path, Conflict
          raise e
        end
        unless exist?
          e = DAV4Rack::LockFailure.new
          e.add_failure @path, NotFound
          raise e
        end
        lock_check(args[:scope])
        entity = file ? file : folder
        begin
          if entity.locked? && entity.locked_for_user?
            raise DAV4Rack::LockFailure.new("Failed to lock: #{@path}")
          else
            # If scope and type are not defined, the only thing we can
            # logically assume is that the lock is being refreshed (office loves
            # to do this for example, so we do a few checks, try to find the lock
            # and ultimately extend it, otherwise we return Conflict for any failure
            if (!args[:scope]) && (!args[:type]) # Perhaps a lock refresh
              http_if = request.env['HTTP_IF']
              if http_if.blank?
                e = DAV4Rack::LockFailure.new
                e.add_failure @path, Conflict
                raise e
              end
              if http_if =~ /([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})/
                l = DmsfLock.find_by(uuid: $1)
              end
              unless l
                e = DAV4Rack::LockFailure.new
                e.add_failure @path, Conflict
                raise e
              end
              l.expires_at = Time.current + 1.week
              l.save!
              @response['Lock-Token'] = l.uuid
              return [1.weeks.to_i, l.uuid]
            end

            scope = "scope_#{(args[:scope] || 'exclusive')}".to_sym
            type = "type_#{(args[:type] || 'write')}".to_sym

            #l should be the instance of the lock we've just created
            l = entity.lock!(scope, type, Time.current + 1.weeks)
            @response['Lock-Token'] = l.uuid
            [1.week.to_i, l.uuid]
          end
        rescue DmsfLockError
          e = DAV4Rack::LockFailure.new
          e.add_failure @path, Conflict
          raise e
        end
      end

      # Unlock
      # Token based unlock (authenticated) will ensure that a correct token is sent, further ensuring
      # ownership of token before permitting unlock
      def unlock(token)
        return NotFound unless exist?
        if token.nil? || token.empty? || (token == '<(null)>') || User.current.anonymous?
          BadRequest
        else
          if token =~ /([a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12})/
            token = $1
          else
            return BadRequest
          end
          begin
            entity = file ? file : folder
            l = DmsfLock.find(token)
            return NoContent unless l
            # Additional case: if a user tries to unlock the file instead of the folder that's locked
            # This should throw forbidden as only the lock at level initiated should be unlocked
            return NoContent unless entity.locked?
            l_entity = l.file || l.folder
            if entity.locked_for_user? || (l_entity != entity)
              Forbidden
            else
              entity.unlock!
              NoContent
            end
          rescue
            BadRequest
          end
        end
      end

      # HTTP POST request.
      #
      # Forbidden, as method should not be utilized.
      def post(request, response)
        raise Forbidden
      end

      # HTTP PUT request.
      def put(request, response)
        raise BadRequest if collection?
        raise Forbidden unless User.current.admin? || User.current.allowed_to?(:file_manipulation, project)
        raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder, false))

        # Ignore file name patterns given in the plugin settings
        pattern = Setting.plugin_redmine_dmsf['dmsf_webdav_ignore']
        pattern = /^(\._|\.DS_Store$|Thumbs.db$)/ if pattern.blank?
        if basename.match(pattern)
          Rails.logger.info "#{basename} ignored"
          return NoContent
        end

        reuse_revision = false

        if exist? # We're over-writing something, so ultimately a new revision
          f = file
          
          # Disable versioning for file name patterns given in the plugin settings.
          pattern = Setting.plugin_redmine_dmsf['dmsf_webdav_disable_versioning']
          if pattern.present? && basename.match(pattern)
            Rails.logger.info "Versioning disabled for #{basename}"
            reuse_revision = true
          end
          
          if reuse_version_for_locked_file(file)
            reuse_revision = true
          end
          
          last_revision = file.last_revision
          if last_revision.size == 0 || reuse_revision
            new_revision = last_revision
            reuse_revision = true
          else
            new_revision = DmsfFileRevision.new
            new_revision.source_revision = last_revision
            if last_revision
              new_revision.major_version = last_revision.major_version
              new_revision.minor_version = last_revision.minor_version
              new_revision.workflow = last_revision.workflow
            end
          end
        else
          raise BadRequest unless (parent.projectless_path == '/' || (parent.exist? && parent.folder))
          f = DmsfFile.new
          f.project_id = project.id
          f.name = basename
          f.dmsf_folder = parent.folder
          f.notification = !Setting.plugin_redmine_dmsf['dmsf_default_notifications'].blank?
          new_revision = DmsfFileRevision.new
          new_revision.minor_version = 0
          new_revision.major_version = 0
        end

        new_revision.dmsf_file = f
        new_revision.user = User.current
        new_revision.name = basename
        new_revision.title = DmsfFileRevision.filename_to_title(basename)
        new_revision.description = nil
        new_revision.comment = nil
        new_revision.increase_version(1) unless reuse_revision
        new_revision.mime_type = Redmine::MimeType.of(new_revision.name)

        # Phusion passenger does not have a method "length" in its model
        # however, includes a size method - so we instead use reflection
        # to determine best approach to problem
        if request.body.respond_to? 'length'
          new_revision.size = request.body.length
        elsif request.body.respond_to? 'size'
          new_revision.size = request.body.size
        else
          new_revision.size = request.content_length # Bad Guess
        end
        
        raise InternalServerError unless new_revision.valid? && f.save

        new_revision.disk_filename = new_revision.new_storage_filename unless reuse_revision

        if new_revision.save
          new_revision.copy_file_content(request.body)
          new_revision.create_digest
          new_revision.save
          # Notifications
          DmsfMailer.deliver_files_updated(project, [f])
        else
          raise InternalServerError
        end

        Created
      end

      def project_id
        project.id if project
      end

      # array of lock info hashes
      # required keys are :time, :token, :depth
      # other valid keys are :scope, :type, :root and :owner
      def lockdiscovery
        entity = file || folder
        return [] unless entity.locked?
        if entity.dmsf_folder && entity.dmsf_folder.locked?
          entity.lock.reverse[0].folder.locks(false) # longwinded way of getting base items locks
        else
          entity.lock(false)
        end
      end

      # returns an array of activelock ox elements
      def lockdiscovery_xml
        x = Nokogiri::XML::DocumentFragment.parse ''
        Nokogiri::XML::Builder.with(x) do |doc|
          doc.lockdiscovery {
            lockdiscovery.each do |lock|
              next if lock.expired?
              doc.activelock {
                doc.locktype { doc.write }
                doc.lockscope {
                  if lock.lock_scope == :scope_exclusive
                    doc.exclusive
                  else
                    doc.shared
                  end
                }
                doc.depth lock.folder.nil? ? '0' : 'infinity'
                doc.owner lock.user.to_s
                if lock.expires_at.nil?
                  doc.timeout 'Infinite'
                else
                  doc.timeout "Second-#{(lock.expires_at.to_i - Time.current.to_i)}"
                end
                lock_entity = lock.folder || lock.file
                lock_path = "#{request.scheme}://#{request.host}:#{request.port}#{path_prefix}#{Addressable::URI.escape(lock_entity.project.identifier)}/"
                lock_path << lock_entity.dmsf_path.map { |e| Addressable::URI.escape(e.respond_to?('name') ? e.name : e.title) }.join('/')
                lock_path << '/' if lock_entity.is_a?(DmsfFolder) && lock_path[-1,1] != '/'
                doc.lockroot { doc.href lock_path }
                if (lock.user.id == User.current.id) || User.current.allowed_to?(:force_file_unlock, project)
                  doc.locktoken { doc.href lock.uuid }
                end
              }
            end
          }
        end
        x
      end

      private
      # Prepare file for download using Rack functionality:
      # Download (see RedmineDmsf::Webdav::Download) extends Rack::File to allow single-file
      # implementation of service for request, which allows for us to pipe a single file through
      # also best-utilising DAV4Rack's implementation.
      def download
        raise NotFound unless file.last_revision
        disk_file = file.last_revision.disk_file
        raise NotFound unless disk_file && File.exist?(disk_file)
        raise Forbidden unless (!parent.exist? || !parent.folder || DmsfFolder.permissions?(parent.folder))
        # If there is no range (start of ranged download, or direct download) then we log the
        # file access, so we can properly keep logged information
        if @request.env['HTTP_RANGE'].nil?
          access = DmsfFileRevisionAccess.new
          access.user = User.current
          access.dmsf_file_revision = file.last_revision
          access.action = DmsfFileRevisionAccess::DownloadAction
          access.save!
        end
        File.new disk_file
      end

private
      def reuse_version_for_locked_file(file)
        locks = file.lock
        locks.each do |lock|
          next if lock.expired?
          # lock should be exclusive but just in case make sure we find this users lock
          next if lock.user != User.current
          if lock.dmsf_file_last_revision_id < file.last_revision.id
            # At least one new revision has been created since the lock was created, reuse that revision.
            return true
          end
        end
        false
      end
      
    end
  end
end
