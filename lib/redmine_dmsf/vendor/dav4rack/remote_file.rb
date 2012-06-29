require 'net/http'
require 'uri'
require 'digest/sha1'
require 'rack/file'

module DAV4Rack
  
  class RemoteFile < Rack::File
    
    attr_accessor :path
    
    alias :to_path :path
    
    # path:: path to file (Actual path, preferably a URL since this is a *REMOTE* file)
    # args:: Hash of arguments:
    #         :size -> Integer - number of bytes
    #         :mime_type -> String - mime type
    #         :last_modified -> String/Time - Time of last modification
    #         :sendfile -> True or String to define sendfile header variation
    #         :cache_directory -> Where to store cached files
    #         :cache_ref -> Reference to be used for cache file name (useful for changing URLs like S3)
    #         :sendfile_prefix -> String directory prefix. Eg: 'webdav' will result in: /wedav/#{path.sub('http://', '')}
    #         :sendfile_fail_gracefully -> Boolean if true will simply proxy if unable to determine proper sendfile
    def initialize(path, args={})
      @path = path
      @args = args
      @heads = {}
      @cache_file = args[:cache_directory] ? cache_file_path : nil
      @redefine_prefix = nil
      if(@cache_file && File.exists?(@cache_file))
        @root = ''
        @path_info = @cache_file
        @path = @path_info
      elsif(args[:sendfile])
        @redefine_prefix = 'sendfile'
        @sendfile_header = args[:sendfile].is_a?(String) ? args[:sendfile] : nil
      else
        setup_remote
      end
      do_redefines(@redefine_prefix) if @redefine_prefix
    end
    
    # env:: Environment variable hash
    # Process the call
    def call(env)
      serving(env)
    end

    # env:: Environment variable hash
    # Return an empty result with the proper header information
    def sendfile_serving(env)
      header = @sendfile_header || env['sendfile.type'] || env['HTTP_X_SENDFILE_TYPE']
      unless(header)
        raise 'Failed to determine proper sendfile header value' unless @args[:sendfile_fail_gracefully]
        setup_remote
        do_redefines('remote')
        call(env)
      end
      prefix = (@args[:sendfile_prefix] || env['HTTP_X_ACCEL_REMOTE_MAPPING']).to_s.sub(/^\//, '').sub(/\/$/, '')
      [200, {
             "Last-Modified" => last_modified,
             "Content-Type" => content_type,
             "Content-Length" => size,
             "Redirect-URL" => @path,
             "Redirect-Host" => @path.scan(%r{^https?://([^/\?]+)}).first.first,
             header => "/#{prefix}"
            },
      ['']]
    end
    
    # env:: Environment variable hash
    # Return self to be processed
    def remote_serving(e)
      [200, {
             "Last-Modified"  => last_modified,
             "Content-Type"   => content_type,
             "Content-Length" => size
            }, self]
    end
    
    # Get the remote file
    def remote_each
      if(@store)
        yield @store
      else
        @con.request_get(@call_path) do |res|
          res.read_body(@store) do |part|
            @cf.write part if @cf
            yield part
          end
        end
      end
    end
    
    # Size based on remote headers or given size
    def size
      @heads['content-length'] || @size
    end
    
    private
    
    # Content type based on provided or remote headers
    def content_type
      @mime_type || @heads['content-type']
    end
    
    # Last modified type based on provided, remote headers or current time
    def last_modified
      @heads['last-modified'] || @modified || Time.now.httpdate
    end

    # Builds the path for the cached file
    def cache_file_path
      raise IOError.new 'Write permission is required for cache directory' unless File.writable?(@args[:cache_directory])
      "#{@args[:cache_directory]}/#{Digest::SHA1.hexdigest((@args[:cache_ref] || @path).to_s + size.to_s + last_modified.to_s)}.cache"
    end
    
    # prefix:: prefix of methods to be redefined
    # Redefine methods to do what we want in the proper situation
    def do_redefines(prefix)
      self.public_methods.each do |method|
        m = method.to_s.dup
        next unless m.slice!(0, prefix.to_s.length + 1) == "#{prefix}_"
        self.class.class_eval "undef :'#{m}'"
        self.class.class_eval "alias :'#{m}' :'#{method}'"
      end
    end
    
    # Sets up all the requirements for proxying a remote file
    def setup_remote
      if(@cache_file)
        begin
          @cf = File.open(@cache_file, 'w+')
        rescue
          @cf = nil
        end
      end
      @uri = URI.parse(@path)
      @con = Net::HTTP.new(@uri.host, @uri.port)
      @call_path = @uri.path + (@uri.query ? "?#{@uri.query}" : '')
      res = @con.request_get(@call_path)
      @heads = res.to_hash
      res.value
      @store = nil
      @redefine_prefix = 'remote'
    end
  end
end
