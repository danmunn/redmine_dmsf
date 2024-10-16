# frozen_string_literal: true

module Dav4rack
  # XML response
  class XmlResponse
    include XmlElements

    def initialize(response, namespaces, http_version: 'HTTP/1.1')
      @response = response
      @namespaces = namespaces
      @http_version = http_version
    end

    def render_xml(xml_body)
      @namespaces.each do |href, prefix|
        xml_body["xmlns:#{prefix}"] = href
      end

      xml_doc = Ox::Document.new(version: '1.0')
      xml_doc << xml_body

      @response.body = Ox.dump(xml_doc, { indent: -1, with_xml: true })

      @response['Content-Type'] = 'application/xml; charset=utf-8'
      @response['Content-Length'] = @response.body.bytesize.to_s
    end

    def multistatus
      multistatus = Ox::Element.new(D_MULTISTATUS)
      yield multistatus
      render_xml multistatus
    end

    def render_failed_precondition(status, href)
      error = Ox::Element.new(D_ERROR)
      case status.code
      when 423
        l = Ox::Element.new(D_LOCK_TOKEN_SUBMITTED)
        l << ox_element(D_HREF, href)
        error << l
      end
      render_xml error
    end

    def render_lock_errors(errors)
      multistatus do |xml|
        errors.each do |href, status|
          r = response href, status
          r << ox_element(D_ERROR, Ox::Element.new(D_LOCK_TOKEN_SUBMITTED)) if status.code == 423
          xml << r
        end
      end
    end

    def render_lockdiscovery(...)
      render_xml ox_element(D_PROP, ox_element(D_LOCKDISCOVERY, activelock(...)))
    end

    #
    # helpers for creating single elements
    #

    def response(href, status)
      r = Ox::Element.new(D_RESPONSE)
      r << ox_element(D_HREF, href)
      r << self.status(status)
      r
    end

    def raw(xml)
      Ox::Raw.new xml
    end

    def status(status)
      ox_element D_STATUS, "#{@http_version} #{status.status_line}"
    end

    private

    def activelock(time:, token:, depth:, scope: nil, type: nil, owner: nil, root: nil)
      Ox::Element.new(D_ACTIVELOCK).tap do |activelock|
        if scope
          value = Ox::Element.new("#{DAV_NAMESPACE_NAME}:#{scope}")
          activelock << ox_element(D_LOCKSCOPE, value)
        end
        if type
          value = Ox::Element.new("#{DAV_NAMESPACE_NAME}:#{type}")
          activelock << ox_element(D_LOCKTYPE, value)
        end
        activelock << ox_element(D_DEPTH, depth)
        activelock << ox_element(D_TIMEOUT, (time ? "Second-#{time}" : INFINITY))
        value = ox_element(D_HREF, token)
        activelock << ox_element(D_LOCKTOKEN, value)
        activelock << ox_element(D_OWNER, owner) if owner
        if root
          value = ox_element(D_HREF, root)
          activelock << ox_element(D_LOCKROOT, value)
        end
      end
    end
  end
end
