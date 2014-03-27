# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn  <dan.munn@munnster.co.uk>
# Copyright (C) 2011-14 Karel Picman <karel.picman@kontron.com>
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

require 'dav4rack'

module RedmineDmsf
  module Webdav
    class Controller < DAV4Rack::Controller

      # Overload default options
      def options
        raise NotFound unless resource.exist?
        response['Allow'] = 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
        response['Dav'] = '1,2,3'
        response['Ms-Author-Via'] = 'DAV'
        OK
      end

      # This is just pain DIRTY
      # to fix some gem bugs we're overriding their controller
      def lock
        begin
          request.env['Timeout'] = request.env['HTTP_TIMEOUT'].split('-',2).join(',') unless request.env['HTTP_TIMEOUT'].nil?
        rescue
          # Nothing here
        end

        request_document.remove_namespaces! if ns.empty? 
        # We re-imlement the function ns - if its return is empty, there are no usable namespaces
        # so to prevent never returning data, we stip all namespaces

        super
      end


      # Overload the default propfind function with this
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

      # root_type:: Root tag name
      # Render XML and set Rack::Response#body= to final XML
      # Another override (they don't seem to flag UTF-8 [at this point I'm considering forking the gem to fix, 
      # and making DMSF compliant on that .. *sigh*
      def render_xml(root_type)
        raise ArgumentError.new 'Expecting block' unless block_given?
        doc = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml_base|
          xml_base.send(root_type.to_s, {'xmlns:D' => 'DAV:'}.merge(resource.root_xml_attributes)) do
            xml_base.parent.namespace = xml_base.parent.namespace_definitions.first
            xml = xml_base['D']
            yield xml
          end
        end
        response.body = doc.to_xml
        response['Content-Type'] = 'application/xml; charset="utf-8"'
        response['Content-Length'] = response.body.bytesize.to_s
      end

      # Returns Resource path with root URI removed
      def implied_path

        return clean_path(@request.path_info.dup) unless @request.path_info.empty?
        c_path = clean_path(@request.path.dup)
        return c_path if c_path.length != @request.path.length

        # If we're here then it's probably down to thin
        return @request.path.dup.gsub!(/^#{Regexp.escape(@request.script_name)}/, '') unless @request.script_name.empty?

        return c_path # This will probably result in a processing error if we hit here
      end

      private 
      def ns(opt_head = '')
        _ns = opt_head
        if(request_document && request_document.root && request_document.root.namespace_definitions.size > 0)
          _ns = request_document.root.namespace_definitions.first.prefix.to_s
          _ns += ':' unless _ns.empty?
        end
        _ns.empty? ? opt_head : _ns
      end

    end
  end
end