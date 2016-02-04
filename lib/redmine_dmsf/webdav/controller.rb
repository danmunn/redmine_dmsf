# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn  <dan.munn@munnster.co.uk>
# Copyright (C) 2011-16 Karel Pičman <karel.picman@kontron.com>
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
      include DAV4Rack::Utils

      # Return response to PROPFIND
      def propfind
        unless(resource.exist?)
          NotFound
        else
          # Win7 hack start          
          if request_document.xpath("//#{ns}propfind").empty? || request_document.xpath("//#{ns}propfind/#{ns}allprop").present?
            properties = resource.properties.map { |prop| DAV4Rack::DAVElement.new(prop.merge(:namespace => DAV4Rack::DAVElement.new(:href => prop[:ns_href]))) }
          # Win7 hack end
          else
            check = request_document.xpath("//#{ns}propfind")
            if(check && !check.empty?)
              properties = request_document.xpath(
                "//#{ns}propfind/#{ns}prop"
              ).children.find_all{ |item|
                item.element?
              }.map{ |item|
                # We should do this, but Nokogiri transforms prefix w/ null href into
                # something valid.  Oops.
                # TODO: Hacky grep fix that's horrible
                hsh = to_element_hash(item)
                if(hsh.namespace.nil? && !ns.empty?)
                  raise BadRequest if request_document.to_s.scan(%r{<#{item.name}[^>]+xmlns=""}).empty?
                end
                hsh
              }.compact
            else
              raise BadRequest
            end
          end
          multistatus do |xml|
            find_resources.each do |resource|
              xml.response do
                unless(resource.propstat_relative_path)
                  xml.href "#{scheme}://#{host}:#{port}#{url_format(resource)}"                  
                else
                  xml.href url_format(resource)
                end
                propstats(xml, get_properties(resource, properties.empty? ? resource.properties : properties))
              end
            end
          end          
        end
      end
    
      # args:: Only argument used: :copy
      # Move Resource to new location. If :copy is provided,
      # Resource will be copied (implementation ease)
      # The only reason for overriding is a typing mistake 'include' -> 'include?' 
      #   and a wrong regular expression for BadGateway check
      def move(*args)
        unless(resource.exist?)
          NotFound
        else
          resource.lock_check if resource.supports_locking? && !args.include?(:copy)
          destination = url_unescape(env['HTTP_DESTINATION'].sub(%r{https?://([^/]+)}, ''))          
          host = $1.gsub(/:\d{2,5}$/, '') if $1
          host = host.gsub(/^.+@/, '') if host
          if(host != request.host)
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
          true          
        end
      end
      
      # Escape URL string
      def url_format(resource)
        # Additionally escape square brackets, otherwise files with 
        # file name like file[1].pdf are not visible in some WebDAV clients
        URI.encode(super, '[]')
      end
      
    end
  end
end