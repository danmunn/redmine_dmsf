# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/uri"
require "#{File.dirname(__FILE__)}/destination_header"
require "#{File.dirname(__FILE__)}/request"
require "#{File.dirname(__FILE__)}/xml_elements"
require "#{File.dirname(__FILE__)}/xml_response"

module Dav4rack
  # Controller
  class Controller
    include Dav4rack::HttpStatus
    include Dav4rack::Utils

    attr_reader :request, :response, :resource

    # request:: Dav4rack::Request
    # response:: Rack::Response
    # options:: Options hash
    # Create a new Controller.
    #
    # options will be passed on to the resource
    def initialize(request, response, options = {})
      @options = options
      @request = request
      @response = response
      @dav_extensions = options[:dav_extensions]
      @always_include_dav_header = !options[:always_include_dav_header].nil?
      @allow_unauthenticated_options_on_root = !options[:allow_unauthenticated_options_on_root].nil?
      setup_resource
      add_dav_header if @always_include_dav_header
    end

    # main entry point, called by the Handler
    def process
      status = skip_authorization? || authenticate ? process_action || OK : HttpStatus::Unauthorized
    rescue HttpStatus::Status => e
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
    # must return an HttpStatus. If nil / false, the resulting status will be
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
      @allow_unauthenticated_options_on_root && request.request_method.casecmp('options').zero? &&
        (request.path_info == '/' || request.path_info.empty?)
    end

    # Return response to OPTIONS
    def options
      status = resource.options request, response
      if status == OK
        add_dav_header
        response['Allow'] ||= 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
        response['Ms-Author-Via'] ||= 'DAV'
      end
      status
    end

    # Return response to HEAD
    def head
      return NotFound unless resource.exist?

      res = resource.head(request, response)
      if res == OK
        response['Etag'] ||= resource.etag
        response['Content-Type'] ||= resource.content_type
        response['Content-Length'] ||= resource.content_length.to_s
        response['Last-Modified'] ||= resource.last_modified.httpdate
      end
      res
    end

    # Return response to GET
    def get
      return NotFound unless resource.exist?

      res = resource.get(request, response)
      if res == OK && !resource.collection?
        response['Etag'] ||= resource.etag
        response['Content-Type'] ||= resource.content_type
        response['Content-Length'] ||= resource.content_length.to_s
        response['Last-Modified'] ||= resource.last_modified.httpdate
      end
      res
    end

    # Return response to PUT
    def put
      if request.get_header('HTTP_CONTENT_RANGE')
        # An origin server that allows PUT on a given target resource MUST send
        # a 400 (Bad Request) response to a PUT request that contains a
        # Content-Range header field.
        # Reference: http://tools.ietf.org/html/rfc7231#section-4.3.4
        Rails.logger.error 'Content-Range on PUT requests is forbidden.'
        BadRequest
      elsif resource.collection?
        Forbidden
      elsif !resource.parent.exist? || !resource.parent.collection?
        Conflict
      else
        resource.lock_check if resource.supports_locking?
        status = resource.put(request)
        response['Location'] ||= request.url_for resource.path if status == Created
        response.body = response['Location'] || ''
        status
      end
    end

    # Return response to POST
    def post
      resource.post request, response
    end

    # Return response to DELETE
    def delete
      return NotFound unless resource.exist?

      resource.lock_check if resource.supports_locking?
      resource.delete
    end

    # Return response to MKCOL
    def mkcol
      return UnsupportedMediaType if request.content_length.to_i.positive?
      return MethodNotAllowed if resource.exist?

      resource.lock_check if resource.supports_locking?
      status = resource.make_collection

      return status unless resource.use_compat_mkcol_response?

      url = request.url_for resource.path, collection: true
      r = XmlResponse.new(response, resource.namespaces)
      r.multistatus do |xml|
        xml << r.response(url, status)
      end
      MultiStatus
    end

    # Move Resource to new location.
    def move
      return NotFound unless resource.exist?
      return BadRequest unless request.depth == 'infinity'

      dest = request.destination
      return BadRequest unless dest

      status = dest.validate(host: request.host, resource_path: resource.path)
      return status if status

      resource.lock_check if resource.supports_locking?
      resource.move dest.path_info
    end

    # Return response to COPY
    def copy
      return NotFound unless resource.exist?
      return BadRequest unless request.depth == 'infinity' || request.depth.zero?

      dest = request.destination
      return BadRequest unless dest

      status = dest.validate(host: request.host, resource_path: resource.path)
      return status if status

      resource.copy dest.path_info
    end

    # Return response to PROPFIND
    def propfind
      return NotFound unless resource.exist?

      ns = request.ns
      document = request.document if request.content_length.to_i.positive?
      propfind = document.xpath("//#{ns}propfind") if document

      # propname request
      if propfind&.xpath("//#{ns}propname")&.first
        r = XmlResponse.new(response, resource.namespaces)
        r.multistatus do |xml|
          xml << Ox::Raw.new(resource.propnames_xml_with_depth)
        end
        return MultiStatus
      end

      properties = if propfind.blank? || propfind.xpath("//#{ns}allprop").first
                     resource.properties
                   elsif (prop = propfind.xpath("//#{ns}prop").first)
                     prop.children
                         .find_all(&:element?)
                         .filter_map do |item|
                           # We should do this, but Nokogiri transforms prefix w/ null href
                           # into something valid.  Oops.
                           # TODO: Hacky grep fix that's horrible
                           hsh = to_element_hash(item)
                           if hsh.namespace.nil? && !ns.empty? && prop.to_s.scan(/<#{item.name}[^>]+xmlns=""/).empty?
                             return BadRequest
                           end

                           hsh
                         end
                   else
                     Rails.logger.error 'No properties found'
                     raise BadRequest
                   end

      properties = properties.map { |property| { element: property } }
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
      return NotFound unless resource.exist?
      return BadRequest unless (doc = request.document)

      resource.lock_check if resource.supports_locking?
      properties = {}
      actions = %w[set remove]
      doc.xpath("/#{request.ns}propertyupdate").children.each do |element|
        action = element.name
        next unless actions.include?(action)

        properties[action] ||= []
        next unless (prp = element.children.detect { |e| e.name == 'prop' })

        prp.children.each do |elm|
          next if elm.name == 'text'

          properties[action] << { element: to_element_hash(elm), value: elm.text }
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
      return BadRequest unless request.depth == 'infinity' || request.depth.zero?

      asked = { depth: depth }
      timeout = request.env['Timeout']
      asked[:timeout] = timeout.split(',').map(&:strip) if timeout
      ns = request.ns
      doc = request.document
      lockinfo = doc&.xpath("//#{ns}lockinfo")
      if lockinfo
        # <D:lockinfo xmlns:D="DAV:">
        #   <D:lockscope>
        #     <D:exclusive/>
        #   </D:lockscope>
        #   <D:locktype>
        #     <D:write/>
        #   </D:locktype>
        #   <D:owner>
        #     <D:href>uraab</D:href>
        #   </D:owner>
        # </D:lockinfo>
        asked[:scope] = lockinfo.xpath("//#{ns}lockscope").children.find_all(&:element?).map(&:name).first
        asked[:type] = lockinfo.xpath("#{ns}locktype").children.find_all(&:element?).map(&:name).first
        asked[:owner] = lockinfo.xpath("//#{ns}owner").children.map(&:text).first
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
        resource.exist? ? OK : Created
      rescue LockFailure => e
        begin
          resource.lock_check
        rescue StandardError => _ex
          return Locked
        end
        r.multistatus do |xml|
          e.path_status.each_pair do |path, status|
            xml << r.response(path, status)
          end
        end
        MultiStatus
      end
    end

    # Unlock current resource
    def unlock
      resource.unlock request.lock_token
    end

    # Perform authentication
    #
    # implement your authentication by overriding Resource#authenticate
    def authenticate
      uname = nil
      password = nil
      if request.authorization?
        auth = Rack::Auth::Basic::Request.new(request.env)
        if auth.basic? && auth.credentials
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
      @resource = resource_class.new(request.unescaped_path_info, request, response, @options)
    end

    # Class of the resource in use
    def resource_class
      @options[:resource_class]
    end

    def add_dav_header
      return if response['Dav']

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
