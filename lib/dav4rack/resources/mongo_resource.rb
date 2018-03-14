# coding: utf-8
# frozen_string_literal: true

require 'mime/types'
require 'mongo'
require 'erb'
require 'dav4rack/security_utils'

module DAV4Rack

  class MongoResource < DAV4Rack::Resource

    def self.database=(db)
      @database = db
    end
    def self.database; @database end


    def setup
      @filesystem = Mongo::Grid::FSBucket.new(self.class.database)
      if @options[:bson]
        @bson = @options[:bson]
      elsif path.empty? || path == '/'
        @bson = {'filename' => '/'}
      else
        @bson = @filesystem.find(filename: /^#{Regexp.escape(path)}\/?$/).first rescue nil
      end
    end

    def child(bson)
      our_options = @options.dup
      @options[:bson] = bson
      child = new_for_path bson['filename']
      @options = our_options
      child
    end

    # If this is a collection, return the child resources.
    def children
      @filesystem.find(filename: /^#{Regexp.escape(@bson['filename'])}[^\/]+\/?$/).map do |bson|
        child bson
      end
    end

    # Is this resource a collection?
    def collection?
      @bson && _collection?(@bson['filename'])
    end

    # Does this recource exist?
    def exist?
      !!@bson
    end

    # Return the creation time.
    def creation_date
      @bson['uploadDate'] || Date.new
    end

    # Return the time of last modification.
    def last_modified
      @bson['uploadDate'] || Date.new
    end

    # Set the time of last modification.
    def last_modified=(time)
    end

    # Return an Etag, an unique hash value for this resource.
    def etag
      @bson['_id'].to_s
    end

    # Return the mime type of this resource.
    def content_type
      @bson['contentType'] || "text/html"
    end

    # Return the size in bytes for this resource.
    def content_length
      @bson['length'] || 0
    end

    # HTTP GET request.
    #
    # Write the content of the resource to the response.body.
    def get(request, response)
      return NotFound unless exist?

      if collection?
        response.body = "<html>".dup
        response.body << "<h2>" + ERB::Util.html_escape(path) + "</h2>"
        children.each do |child|
          name = ERB::Util.html_escape child.name

          path = ERB::Util.html_escape request.path_for(child.path,
                                                        collection: child.collection?)
          response.body << "<a href='" + path + "'>" + name + "</a>"
          response.body << "</br>"
        end
        response.body << "</html>"
        response['Content-Type'] = 'text/html'
      else
        @filesystem.open_download_stream_by_name(path, revision: -1) do |s|
          # not sure if the copying is necessary, but keeping the reference to
          # s outside the block seems unsafe as we dont know if/when that
          # stream will be closed
          #response.body = s
          response.body = s.read
          response['Content-Type'] = @bson['contentType']
        end
      end
      OK
    rescue Mongo::Error::InvalidFileRevision
      NotFound
    end

    # HTTP PUT request.
    #
    # Save the content of the request.body.
    def put(request, response)
      exists = exist?

      @filesystem.open_upload_stream(
        path, content_type: content_type_for(path)
      ) { |f| f.write request.body }

      exists ? NoContent : Created
    end

    # HTTP POST request.
    #
    # Usually forbidden.
    def post(request, response)
      raise HTTPStatus::Forbidden
    end

    # HTTP DELETE request.
    #
    # Delete this resource.
    def delete
      if collection?
        @filesystem.find(filename: /^#{Regexp.escape(@bson['filename'])}/).each do |bson|
          @filesystem.delete(bson['_id'])
        end
      else
        @filesystem.delete(@bson['_id'])
      end
      NoContent
    end

    # HTTP COPY request.
    #
    # Copy this resource to given destination path.
    def copy(dest_path, overwrite = false, depth = :infinity)
      dest = new_for_path dest_path
      dest.collection! if collection?

      src = @bson['filename']
      dst = dest.path
      exists = @filesystem.find(filename: /^#{Regexp.escape(dst)}/).any?

      if overwrite
        @filesystem.find(filename: /^#{Regexp.escape(dst)}/).each do |bson|
          @filesystem.delete bson['_id']
        end
      elsif @filesystem.find(filename: /^#{Regexp.escape(dst)}/).any?
        return PreconditionFailed
      end

      @filesystem.find(filename: /^#{Regexp.escape(src)}/).each do |bson|
        src_name = bson['filename']
        dst_name = dst + src_name.slice(src.length, src_name.length)

        @filesystem.open_download_stream_by_name(src_name) do |i|
          @filesystem.open_upload_stream(dst_name,
                                         content_type: bson['contentType']) do |o|
            i.each{|chunk| o.write chunk }
          end
        end
      end

      exists ? NoContent : Created
    end

    # HTTP MOVE request.
    #
    # Move this resource to given destination path.
    def move(dest_path, overwrite = false)
      dest = new_for_path dest_path
      dest.collection! if collection?

      src = @bson['filename']
      dst = dest.path
      exists = @filesystem.find(filename: /^#{Regexp.escape(dst)}/).any?

      if overwrite
        @filesystem.find(filename: /^#{Regexp.escape(dst)}/).each do |bson|
          @filesystem.delete bson['_id']
        end
      elsif @filesystem.find(filename: /^#{Regexp.escape(dst)}/).any?
        return PreconditionFailed
      end

      @filesystem.find(filename: /^#{Regexp.escape(src)}/).each do |bson|
        src_name = bson['filename']
        dst_name = dst + src_name.slice(src.length, src_name.length)

        # http://mongoid.org/docs/persistence/atomic.html
        # http://rubydoc.info/github/mongoid/mongoid/master/Mongoid/Collection#update-instance_method
        mongo_collection.find_one_and_update({'_id' => bson['_id']}, {'$set' => {'filename' => dst_name}}, safe: true)

      end

      exists ? NoContent : Created
    end

    # HTTP MKCOL request.
    #
    # Create this resource as collection.
    def make_collection

      if @filesystem.find(filename: path).any?
        raise 'resource exists'
      end
      collection!
      @filesystem.open_upload_stream(path) { |f| }

      Created
    end

    def collection!
      path << '/' unless _collection?(path)
    end

    def authenticate(user, pass)
      if(@options[:username])
        # This comparison uses & so that it doesn't short circuit and
        # uses `variable_size_secure_compare` so that length information
        # isn't leaked.
        SecurityUtils.variable_size_secure_compare(
          user, @options[:username]
        ) &
          SecurityUtils.variable_size_secure_compare(
            pass, @options[:password]
          )
      else
        true
      end
    end

    private

    def mongo_collection
      @mongo_collection ||= self.class.database['fs.files']
    end

    def content_type_for(filename)
      MIME::Types.type_for(filename).first.to_s || 'text/html'
    end

    def _collection?(path)
      path && path.end_with?('/')
    end

  end

end
