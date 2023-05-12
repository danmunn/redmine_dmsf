# frozen_string_literal: true

require 'ostruct'

module Dav4rack
  # Simple wrapper for formatted elements
  class DAVElement < OpenStruct
    def [](key)
      send(key)
    end
  end

  # Utils
  module Utils
    DEFAULT_HTTP_VERSION = 'HTTP/1.1'

    def to_element_hash(element)
      ns = element.namespace
      DAVElement.new(
        namespace: ns,
        name: element.name,
        ns_href: ns&.href,
        children: element.children.filter_map { |e| to_element_hash(e) if e.element? },
        attributes: attributes_hash(element)
      )
    end

    def to_element_key(element)
      ns = element.namespace
      "#{ns&.href}!!#{element.name}"
    end

    def http_version
      DEFAULT_HTTP_VERSION
    end

    private

    def attributes_hash(node)
      node.attributes.each_with_object({}) do |(_key, attr), ret|
        ret[attr.name] = attr.value
      end
    end
  end
end
