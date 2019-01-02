# frozen_string_literal: true

require 'uri'
require 'dav4rack/destination_header'
require 'dav4rack/request'
require 'dav4rack/xml_elements'
require 'dav4rack/xml_response'

module DAV4Rack

  class Controller
    include DAV4Rack::HTTPStatus
    include DAV4Rack::Utils

    attr_reader :request, :response, :resource


    # request:: DAV4Rack::Request
    # response:: Rack::Response
    # options:: Options hash
    # Create a new Controller.
    #
    # options will be passed on to the resource
    def initialize(request, response, options={})
      @options = options

      @request = request
      @response = response

      @dav_extensions = options[:dav_extensions]

      @always_include_dav_header = !!options[:always_include_dav_header]
      @allow_unauthenticated_options_on_root = !!options[:allow_unauthenticated_options_on_root]

      setup_resource

      if @always_include_dav_header
        add_dav_header
      end
    end


    # main entry point, called by the Handler
    def process
      if skip_authorization? || authenticate
        status = process_action || OK
      else
        status = HTTPStatus::Unauthorized
      end
    rescue HTTPStatus::Status => e
      status = e
    ensure
      if status
        response.status = status.code
        if status.code == 401
          response.body = authentication_error_message
          response['WWW-Authenticate'] = "Basic realm=\"#{authentication_realm}\""
        end
      end
    end


    private

    # delegates to the handler method matching this requests http method.
    # must return an HTTPStatus. If nil / false, the resulting status will be
    # 200/OK
    def process_action
      send request.request_method.downcase
    end


    # if true, resource#authenticate will never be called
    def skip_authorization?

      # Microsoft Web Client workaround (from RedmineDmsf plugin):
      #
      # MS web client will not attempt any authentication (it'd seem)
      # until it's acknowledged a completed OPTIONS request.
      #
      # If the request method is OPTIONS return true, controller will simply
      # call the options method within, which accesses nothing, just returns
      # headers about the dav env.
      return @allow_unauthenticated_options_on_root &&
        request.request_method.downcase == 'options' &&
        (request.path_info == '/' || request.path_info.empty?)

    end


    # Return response to OPTIONS
    def options
      status = resource.options request, response
      if(status == OK)
        add_dav_header
        response['Allow'] ||= 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
        response['Ms-Author-Via'] ||= 'DAV'
      end
      status
    end

    # Return response to HEAD
    def head
      if(resource.exist?)
        res = resource.head(request, response)
        if(res == OK)
          response['Etag'] ||= resource.etag
          response['Content-Type'] ||= resource.content_type
          response['Content-Length'] ||= resource.content_length.to_s
          response['Last-Modified'] ||= resource.last_modified.httpdate
        end
        res
      else
        NotFound
      end
    end

    # Return response to GET
    def get
      if(resource.exist?)
        res = resource.get(request, response)
        if(res == OK && !resource.collection?)
          response['Etag'] ||= resource.etag
          response['Content-Type'] ||= resource.content_type
          response['Content-Length'] ||= resource.content_length.to_s
          response['Last-Modified'] ||= resource.last_modified.httpdate
        end
        res
      else
        NotFound
      end
    end

    # Return response to PUT
    def put
      if request.get_header('HTTP_CONTENT_RANGE')
        # An origin server that allows PUT on a given target resource MUST send
        # a 400 (Bad Request) response to a PUT request that contains a
        # Content-Range header field.
        # Reference: http://tools.ietf.org/html/rfc7231#section-4.3.4
        Logger.error 'Content-Range on PUT requests is forbidden.'
        BadRequest
      elsif(resource.collection?)
        Forbidden
      elsif(!resource.parent_exists? || !resource.parent_collection?)
        Conflict
      else
        resource.lock_check if resource.supports_locking?
        status = resource.put(request, response)
        if status == Created
          response['Location'] ||= request.url_for resource.path
        end
        response.body = response['Location'] || ''
        status
      end
    end

    # Return response to POST
    def post
      resource.post(request, response)
    end

    # Return response to DELETE
    def delete
      if(resource.exist?)
        resource.lock_check if resource.supports_locking?
        resource.delete
      else
        NotFound
      end
    end

    # Return response to MKCOL
    def mkcol
      if request.content_length.to_i > 0
        return UnsupportedMediaType
      end
      return MethodNotAllowed if resource.exist?

      resource.lock_check if resource.supports_locking?
      status = resource.make_collection

      if(resource.use_compat_mkcol_response?)
        url = request.url_for resource.path, collection: true
        r = XmlResponse.new(response, resource.namespaces)
        r.multistatus do |xml|
          xml << r.response(url, status)
        end
        MultiStatus
      else
        status
      end
    end


    # Move Resource to new location.
    def move
      return NotFound unless(resource.exist?)
      return BadRequest unless request.depth == :infinity

      return BadRequest unless dest = request.destination
      if status = dest.validate(host: request.host,
                                resource_path: resource.path)
        return status
      end

      resource.lock_check if resource.supports_locking?

      return resource.move dest.path_info, request.overwrite?
    end


    # Return response to COPY
    def copy
      return NotFound   unless(resource.exist?)
      return BadRequest unless request.depth == :infinity or request.depth == 0

      return BadRequest unless dest = request.destination
      if status = dest.validate(host: request.host,
                                resource_path: resource.path)
        return status
      end

      resource.copy dest.path_info, request.overwrite?, request.depth
    end

    # Return response to PROPFIND
    def propfind
      return NotFound unless resource.exist?

      ns = request.ns
      document = request.document if request.content_length.to_i > 0
      propfind = document.xpath("//#{ns}propfind") if document

      # propname request
      if propfind and propfind.xpath("//#{ns}propname").first

        r = XmlResponse.new(response, resource.namespaces)
        r.multistatus do |xml|
          xml << Ox::Raw.new(resource.propnames_xml_with_depth)
        end
        return MultiStatus
      end


      properties = if propfind.nil? or
                      propfind.empty? or
                      propfind.xpath("//#{ns}allprop").first

        resource.properties

      elsif prop = propfind.xpath("//#{ns}prop").first

        prop.children
          .find_all{ |item| item.element? }
          .map{ |item|
            # We should do this, but Nokogiri transforms prefix w/ null href
            # into something valid.  Oops.
            # TODO: Hacky grep fix that's horrible
            hsh = to_element_hash(item)
            if(hsh.namespace.nil? && !ns.empty?)
              return BadRequest if prop.to_s.scan(%r{<#{item.name}[^>]+xmlns=""}).empty?
            end
            hsh
          }.compact
      else
        Logger.error "no properties found"
        raise BadRequest
      end

      properties = properties.map{|property| {element: property}}
      properties = resource.propfind_add_additional_properties(properties)

      prop_xml = resource.properties_xml_with_depth(get: properties)

      r = XmlResponse.new(response, resource.namespaces)
      r.multistatus do |xml|
        xml << r.raw(prop_xml)
      end
      MultiStatus
    end


    # Return response to PROPPATCH
    def proppatch
      return NotFound   unless resource.exist?
      return BadRequest unless doc = request.document

      resource.lock_check if resource.supports_locking?
      properties = {}
      doc.xpath("/#{request.ns}propertyupdate").children.each do |element|
        action = element.name
        if action == 'set' || action == 'remove'
          properties[action] ||= []
          if prp = element.children.detect{|e|e.name == 'prop'}
            prp.children.each do |elm|
              next if elm.name == 'text'
              properties[action] << { element: to_element_hash(elm), value: elm.text }
            end
          end
        end
      end

      r = XmlResponse.new(response, resource.namespaces)
      r.multistatus do |xml|
        xml << Ox::Raw.new(resource.properties_xml_with_depth(properties))
      end
      MultiStatus
    end


    # Lock current resource
    # NOTE: This will pass an argument hash to Resource#lock and
    # wait for a success/failure response.
    def lock
      depth = request.depth
      return BadRequest unless depth == 0 || depth == :infinity

      asked = { depth: depth }

      if timeout = request.env['Timeout']
        asked[:timeout] = timeout.split(',').map{|x|x.strip}
      end

      ns = request.ns
      if doc = request.document and lockinfo = doc.xpath("//#{ns}lockinfo")

        asked[:scope] = lockinfo.xpath("//#{ns}lockscope").children.find_all{|n|n.element?}.map{|n|n.name}.first
        asked[:type] = lockinfo.xpath("#{ns}locktype").children.find_all{|n|n.element?}.map{|n|n.name}.first
        asked[:owner] = lockinfo.xpath("//#{ns}owner/#{ns}href").children.map{|n|n.text}.first
      end

      r = XmlResponse.new(response, resource.namespaces)
      begin

        lock_time, locktoken = resource.lock(asked)

        r.render_lockdiscovery(
          time: lock_time,
          token: locktoken,
          depth: asked[:depth].to_s,
          scope: asked[:scope],
          type: asked[:type],
          owner: asked[:owner]
        )

        response.headers['Lock-Token'] = "<#{locktoken}>"
        return resource.exist? ? OK : Created

      rescue LockFailure => e

        r.multistatus do |xml|
          e.path_status.each_pair do |path, status|
            xml << r.response(path, status)
          end
        end

        return MultiStatus
      end
    end

    # Unlock current resource
    def unlock
      resource.unlock(request.lock_token)
    end



    # Perform authentication
    #
    # implement your authentication by overriding Resource#authenticate
    def authenticate
      uname = nil
      password = nil
      if request.authorization?
        auth = Rack::Auth::Basic::Request.new(request.env)
        if(auth.basic? && auth.credentials)
          uname = auth.credentials[0]
          password = auth.credentials[1]
        end
      end
      resource.authenticate uname, password
    end

    def authentication_error_message
      resource.authentication_error_message
    end

    def authentication_realm
      resource.authentication_realm
    end


    # override this for custom resource initialization
    def setup_resource
      @resource = resource_class.new(
        request.unescaped_path_info, request, response, @options
      )
    end


    # Class of the resource in use
    def resource_class
      unless @options[:resource_class]
        require 'dav4rack/resources/file_resource'
        @options[:resource_class] = FileResource
        @options[:root] ||= Dir.pwd
      end

      @options[:resource_class]
    end


    def add_dav_header
      unless response['Dav']
        dav_support = ['1']
        if resource.supports_locking?
          # compliance is resource specific, only advertise 2 (locking) if
          # supported on the resource.
          dav_support << '2'
        end
        dav_support += @dav_extensions if @dav_extensions
        response['Dav'] = dav_support * ', '
      end
    end

  end

end
