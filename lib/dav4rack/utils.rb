# frozen_string_literal: true

require 'ostruct'

module DAV4Rack

  # Simple wrapper for formatted elements
  class DAVElement < OpenStruct
    def [](key)
      self.send(key)
    end
  end

  module Utils
    DEFAULT_HTTP_VERSION = 'HTTP/1.1'

    def to_element_hash(element)
      ns = element.namespace
      DAVElement.new(
        :namespace => ns,
        :name => element.name,
        :ns_href => (ns.href if ns),
        :children => element.children.collect{|e|
          to_element_hash(e) if e.element?
        }.compact,
        :attributes => attributes_hash(element)
      )
    end

    def to_element_key(element)
      ns = element.namespace
      "#{ns.href if ns}!!#{element.name}"
    end

    def http_version
      DEFAULT_HTTP_VERSION
    end

    private
    def attributes_hash(node)
      node.attributes.inject({}) do |ret, (key,attr)|
        ret[attr.name] = attr.value
        ret
      end
    end
  end

end
