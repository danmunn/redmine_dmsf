require 'uri'

module DAV4Rack
  
  class Controller
    include DAV4Rack::HTTPStatus
    
    attr_reader :request, :response, :resource

    # request:: Rack::Request
    # response:: Rack::Response
    # options:: Options hash
    # Create a new Controller.
    # NOTE: options will be passed to Resource
    def initialize(request, response, options={})
      raise Forbidden if request.path_info.include?('..')
      @request = request
      @response = response
      @options = options
      @resource = resource_class.new(actual_path, implied_path, @request, @response, @options)
    end
    
    # s:: string
    # Escape URL string
    def url_format(resource)
      ret = URI.escape(resource.public_path)
      if resource.collection? and ret[-1,1] != '/'
        ret += '/'
      end
      ret
    end
    
    # s:: string
    # Unescape URL string
    def url_unescape(s)
      URI.unescape(s)
    end  
    
    # Return response to OPTIONS
    def options
      response["Allow"] = 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
      response["Dav"] = "1, 2"
      response["Ms-Author-Via"] = "DAV"
      OK
    end
    
    # Return response to HEAD
    def head
      if(resource.exist?)
        response['Etag'] = resource.etag
        response['Content-Type'] = resource.content_type
        response['Last-Modified'] = resource.last_modified.httpdate
        OK
      else
        NotFound
      end
    end
    
    # Return response to GET
    def get
      if(resource.exist?)
        res = resource.get(request, response)
        if(res == OK && !resource.collection?)
          response['Etag'] = resource.etag
          response['Content-Type'] = resource.content_type
          response['Content-Length'] = resource.content_length.to_s
          response['Last-Modified'] = resource.last_modified.httpdate
        end
        res
      else
        NotFound
      end
    end

    # Return response to PUT
    def put
      if(resource.collection?)
        Forbidden
      elsif(!resource.parent_exists? || !resource.parent.collection?)
        Conflict
      else
        resource.lock_check
        status = resource.put(request, response)
        response['Location'] = "#{scheme}://#{host}:#{port}#{url_format(resource)}" if status == Created
        response.body = response['Location']
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
        resource.lock_check
        resource.delete
      else
        NotFound
      end
    end
    
    # Return response to MKCOL
    def mkcol
      resource.lock_check
      status = resource.make_collection
      gen_url = "#{scheme}://#{host}:#{port}#{url_format(resource)}" if status == Created
      if(resource.use_compat_mkcol_response?)
        multistatus do |xml|
          xml.response do
            xml.href gen_url
            xml.status "#{http_version} #{status.status_line}"
          end
        end
      else
        response['Location'] = gen_url
        status
      end
    end
    
    # Return response to COPY
    def copy
      move(:copy)
    end

    # args:: Only argument used: :copy
    # Move Resource to new location. If :copy is provided,
    # Resource will be copied (implementation ease)
    def move(*args)
      unless(resource.exist?)
        NotFound
      else
        resource.lock_check unless args.include?(:copy)
        destination = url_unescape(env['HTTP_DESTINATION'].sub(%r{https?://([^/]+)}, ''))
        dest_host = $1
        if(dest_host && dest_host.gsub(/:\d{2,5}$/, '') != request.host)
          BadGateway
        elsif(destination == resource.public_path)
          Forbidden
        else
          collection = resource.collection?
          dest = resource_class.new(destination, clean_path(destination), @request, @response, @options.merge(:user => resource.user))
          status = nil
          if(args.include?(:copy))
            status = resource.copy(dest, overwrite)
          else
            return Conflict unless depth.is_a?(Symbol) || depth > 1
            status = resource.move(dest, overwrite)
          end
          response['Location'] = "#{scheme}://#{host}:#{port}#{url_format(dest)}" if status == Created
          # RFC 2518
          if collection
            multistatus do |xml|
              xml.response do
                xml.href "#{scheme}://#{host}:#{port}#{url_format(status == Created ? dest : resource)}"
                xml.status "#{http_version} #{status.status_line}"
              end
            end
          else
            status
          end
        end
      end
    end
    
    # Return respoonse to PROPFIND
    def propfind
      unless(resource.exist?)
        NotFound
      else
        unless(request_document.xpath("//#{ns}propfind/#{ns}allprop").empty?)
          names = resource.property_names
        else
          names = (
            ns.empty? ? request_document.remove_namespaces! : request_document
          ).xpath(
            "//#{ns}propfind/#{ns}prop"
          ).children.find_all{ |item|
            item.element? && item.name.start_with?(ns)
          }.map{ |item|
            item.name.sub("#{ns}::", '')
          }
          raise BadRequest if names.empty?
          names = resource.property_names if names.empty?
        end
        multistatus do |xml|
          find_resources.each do |resource|
            xml.response do
              unless(resource.propstat_relative_path)
                xml.href "#{scheme}://#{host}:#{port}#{url_format(resource)}"
              else
                xml.href url_format(resource)
              end
              propstats(xml, get_properties(resource, names))
            end
          end
        end
      end
    end
    
    # Return response to PROPPATCH
    def proppatch
      unless(resource.exist?)
        NotFound
      else
        resource.lock_check
        prop_rem = request_match('/propertyupdate/remove/prop').children.map{|n| [n.name] }
        prop_set = request_match('/propertyupdate/set/prop').children.map{|n| [n.name, n.text] }
        multistatus do |xml|
          find_resources.each do |resource|
            xml.response do
              xml.href "#{scheme}://#{host}:#{port}#{url_format(resource)}"
              propstats(xml, set_properties(resource, prop_set))
            end
          end
        end
      end
    end


    # Lock current resource
    # NOTE: This will pass an argument hash to Resource#lock and
    # wait for a success/failure response. 
    def lock
      lockinfo = request_document.xpath("//#{ns}lockinfo")
      asked = {}
      asked[:timeout] = request.env['Timeout'].split(',').map{|x|x.strip} if request.env['Timeout']
      asked[:depth] = depth
      unless([0, :infinity].include?(asked[:depth]))
        BadRequest
      else
        asked[:scope] = lockinfo.xpath("//#{ns}lockscope").children.find_all{|n|n.element?}.map{|n|n.name}.first
        asked[:type] = lockinfo.xpath("#{ns}locktype").children.find_all{|n|n.element?}.map{|n|n.name}.first
        asked[:owner] = lockinfo.xpath("//#{ns}owner/#{ns}href").children.map{|n|n.text}.first
        begin
          lock_time, locktoken = resource.lock(asked)
          render_xml(:prop) do |xml|
            xml.lockdiscovery do
              xml.activelock do
                if(asked[:scope])
                  xml.lockscope do
                    xml.send(asked[:scope])
                  end
                end
                if(asked[:type])
                  xml.locktype do
                    xml.send(asked[:type])
                  end
                end
                xml.depth asked[:depth].to_s
                xml.timeout lock_time ? "Second-#{lock_time}" : 'infinity'
                xml.locktoken do
                  xml.href locktoken
                end
                if(asked[:owner])
                  xml.owner asked[:owner]
                end
              end
            end
          end
          response.status = resource.exist? ? OK : Created
        rescue LockFailure => e
          multistatus do |xml|
            e.path_status.each_pair do |path, status|
              xml.response do
                xml.href path
                xml.status "#{http_version} #{status.status_line}"
              end
            end
          end
        end
      end
    end

    # Unlock current resource
    def unlock
      resource.unlock(lock_token)
    end

    # Perform authentication
    # NOTE: Authentication will only be performed if the Resource
    # has defined an #authenticate method
    def authenticate
      authed = true
      if(resource.respond_to?(:authenticate, true))
        authed = false
        uname = nil
        password = nil
        if(request.env['HTTP_AUTHORIZATION'])
          auth = Rack::Auth::Basic::Request.new(request.env)
          if(auth.basic? && auth.credentials)
            uname = auth.credentials[0]
            password = auth.credentials[1]
          end
        end
        authed = resource.send(:authenticate, uname, password)
      end
      raise Unauthorized unless authed
    end
    
    # ************************************************************
    # private methods
    
    private

    # Request environment variables
    def env
      @request.env
    end
    
    # Current request scheme (http/https)
    def scheme
      request.scheme
    end
    
    # Request host
    def host
      request.host
    end
    
    # Request port
    def port
      request.port
    end
    
    # Class of the resource in use
    def resource_class
      @options[:resource_class]
    end

    # Root URI path for the resource
    def root_uri_path
      @options[:root_uri_path]
    end
    
    # Returns Resource path with root URI removed
    def implied_path

      return clean_path(@request.path_info.dup) unless @request.path_info.empty?
      c_path = clean_path(@request.path.dup)
      return c_path if c_path.length != @request.path.length

      #if we're here then it's probably down to thin
      return @request.path.dup.gsub!(/^#{Regexp.escape(@request.script_name)}/, '') unless @request.script_name.empty?

      return c_path #This will probably result in a processing error if we hit here
    end
    
    # x:: request path
    # Unescapes path and removes root URI if applicable
    def clean_path(x)
      ip = url_unescape(x)
      ip.gsub!(/^#{Regexp.escape(root_uri_path)}/, '') if root_uri_path
      ip
    end
    
    # Unescaped request path
    def actual_path
      url_unescape(@request.path.dup)
    end

    # Lock token if provided by client
    def lock_token
      env['HTTP_LOCK_TOKEN'] || nil
    end
    
    # Requested depth
    def depth
      d = env['HTTP_DEPTH']
      if(d =~ /^\d+$/)
        d = d.to_i
      else
        d = :infinity
      end
      d
    end

    # Current HTTP version being used
    def http_version
      env['HTTP_VERSION'] || env['SERVER_PROTOCOL'] || 'HTTP/1.0'
    end
    
    # Overwrite is allowed
    def overwrite
      env['HTTP_OVERWRITE'].to_s.upcase != 'F'
    end

    # Find resources at depth requested
    def find_resources(with_current_resource=true)
      ary = nil
      case depth
      when 0
        ary = []
      when 1
        ary = resource.children
      else
        ary = resource.descendants
      end
      with_current_resource ? [resource] + ary : ary
    end
    
    # XML parsed request
    def request_document
      @request_document ||= Nokogiri.XML(request.body.read)
    rescue
      raise BadRequest
    end

    # Namespace being used within XML document
    # TODO: Make this better
    def ns
      _ns = ''
      if(request_document && request_document.root && request_document.root.namespace_definitions.size > 0)
        _ns = request_document.root.namespace_definitions.first.prefix.to_s
        _ns += ':' unless _ns.empty?
      end
      _ns
    end
    
    # pattern:: XPath pattern
    # Search XML document for given XPath
    # TODO: Stripping namespaces not so great
    def request_match(pattern)
      request_document.remove_namespaces!.xpath(pattern, request_document.root.namespaces)
    end

    # root_type:: Root tag name
    # Render XML and set Rack::Response#body= to final XML
    def render_xml(root_type)
      raise ArgumentError.new 'Expecting block' unless block_given?
      doc = Nokogiri::XML::Builder.new do |xml_base|
        xml_base.send(root_type.to_s, {'xmlns:D' => 'DAV:'}.merge(resource.root_xml_attributes)) do
          xml_base.parent.namespace = xml_base.parent.namespace_definitions.first
          xml = xml_base['D']
          yield xml
        end
      end
     
      if(@options[:pretty_xml])
        response.body = doc.to_xml
      else
        response.body = doc.to_xml(
          :save_with => Nokogiri::XML::Node::SaveOptions::AS_XML
        )
      end
      response["Content-Type"] = 'text/xml; charset="utf-8"'
      response["Content-Length"] = response.body.size.to_s
    end
      
    # block:: block
    # Creates a multistatus response using #render_xml and
    # returns the correct status
    def multistatus(&block)
      render_xml(:multistatus, &block)
      MultiStatus
    end
    
    # xml:: Nokogiri::XML::Builder
    # errors:: Array of errors
    # Crafts responses for errors
    def response_errors(xml, errors)
      for path, status in errors
        xml.response do
          xml.href "#{scheme}://#{host}:#{port}#{URI.escape(path)}"
          xml.status "#{http_version} #{status.status_line}"
        end
      end
    end

    # resource:: Resource
    # names:: Property names
    # Returns array of property values for given names
    def get_properties(resource, names)
      stats = Hash.new { |h, k| h[k] = [] }
      for name in names
        begin
          val = resource.get_property(name)
          stats[OK].push [name, val]
        rescue Unauthorized => u
          raise u
        rescue Status
          stats[$!.class] << name
        end
      end
      stats
    end

    # resource:: Resource
    # pairs:: name value pairs
    # Sets the given properties
    def set_properties(resource, pairs)
      stats = Hash.new { |h, k| h[k] = [] }
      for name, value in pairs
        begin
          stats[OK] << [name, resource.set_property(name, value)]
        rescue Unauthorized => u
          raise u
        rescue Status
          stats[$!.class] << name
        end
      end
      stats
    end
    
    # xml:: Nokogiri::XML::Builder
    # stats:: Array of stats
    # Build propstats response
    def propstats(xml, stats)
      return if stats.empty?
      for status, props in stats
        xml.propstat do
          xml.prop do
            for name, value in props
              if(value.is_a?(Nokogiri::XML::DocumentFragment))
                xml.__send__ :insert, value
              elsif(value.is_a?(Nokogiri::XML::Node))
                xml.send(name) do
                  xml_convert(xml, value)
                end
              elsif(value.is_a?(Symbol))
                xml.send(name) do
                  xml.send(value)
                end
              else
                xml.send(name, value)
              end
            end
          end
          xml.status "#{http_version} #{status.status_line}"
        end
      end
    end
    
    # xml:: Nokogiri::XML::Builder
    # element:: Nokogiri::XML::Element
    # Converts element into proper text
    def xml_convert(xml, element)
      xml.doc.root.add_child(element)
    end

  end

end 
