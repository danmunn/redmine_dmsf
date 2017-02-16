# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2012    Daniel Munn  <dan.munn@munnster.co.uk>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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
require 'addressable/uri'

module RedmineDmsf
  module Webdav
    class Controller < DAV4Rack::Controller
      include DAV4Rack::Utils

      # Return response to OPTIONS
      def options
        # exist? returns false if user is anonymous for ProjectResource and DmsfResource, but not for IndexResource.
        if resource.exist?
          # resource exists and user is not anonymous.
          add_dav_header
          response['Allow'] = 'OPTIONS,HEAD,GET,PROPFIND'
          webdav_setting = Setting.plugin_redmine_dmsf['dmsf_webdav_strategy']
          if webdav_setting && (webdav_setting != 'WEBDAV_READ_ONLY')
            response['Allow'] << ',PUT,POST,DELETE,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
          end
          response['Ms-Author-Via'] = 'DAV'
          OK
        elsif resource.really_exist? &&
              !request.user_agent.nil? && request.user_agent.downcase.include?('microsoft office') &&
              User.current && User.current.anonymous?
          # resource actually exist, but this was an anonymous request from MsOffice so respond with 405,
          # hopefully the resource did actually exist but failed because of anon.
          # If responding with 401 then MsOffice will fail.
          # If responding with 200 then MsOffice will think that anonymous access is ok for everything.
          # Responding with 405 is a workaround found in https://support.microsoft.com/en-us/kb/2019105
          MethodNotAllowed
        else
          # Return NotFound if resource does not exist and the request is not anonymous from MsOffice
          NotFound
        end
      end

      # Return response to HEAD
      def head
        # exist? returns false if user is anonymous for ProjectResource and DmsfResource, but not for IndexResource.
        if resource.exist?
          # resource exists and user is not anonymous.
          super
        elsif resource.really_exist? &&
              !request.user_agent.nil? && request.user_agent.downcase.include?('microsoft office') &&
              User.current && User.current.anonymous?
          # resource said it don't exist, but this was an anonymous request from MsOffice so respond anyway
          # Can not call super here since it calls resource.exist? which will fail
          response['Etag'] = resource.etag
          response['Content-Type'] = resource.content_type
          response['Last-Modified'] = resource.last_modified.httpdate
          OK
        else
          # Return NotFound if resource does not exist and the request is not anonymous from MsOffice
          NotFound
        end          
      end

      # Return response to PROPFIND
      def propfind
        return MethodNotAllowed if resource && !resource.public_path.start_with?('/dmsf/webdav')
        unless resource.exist?
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
          
          if depth != 0
            # Only use cache for requests with a depth>0, depth=0 responses are already fast.
            pinfo = resource.path.split('/').drop(1)
            if (pinfo.length == 0) # If this is the base_path, we're at root
              # Don't know when projects are added/removed from the visibility list for this user,
              # so don't cache root.
            elsif (pinfo.length == 1) #This is first level, and as such, project path
              propfind_key = "PROPFIND/#{resource.resource.project_id}"
            else # We made it all the way to DMSF Data
              if resource.collection?
                # Only store collections in the cache since responses to files are simple and fast already.
                propfind_key = "PROPFIND/#{resource.resource.project_id}/#{resource.resource.folder.id}"
              end
            end
          end
          
          if propfind_key.nil?
            # This PROPFIND is never cached so always create a new response
            create_propfind_response(properties)
          else
            response.body = RedmineDmsf::Webdav::Cache.read(propfind_key)
            if !response.body.nil?
              # Found cached PROPFIND, fill in Content-Type and Content-Length
              response["Content-Type"] = 'text/xml; charset="utf-8"'
              response["Content-Length"] = response.body.size.to_s
            else
              # No cached PROPFIND found
              # Remove .invalid entry for this propfind since we are now creating a new valid propfind
              RedmineDmsf::Webdav::Cache.delete("#{propfind_key}.invalid")
              create_propfind_response(properties)

              # Cache response.body, but only if no .invalid entry was stored while creating the propfind
              RedmineDmsf::Webdav::Cache.write(propfind_key, response.body) unless RedmineDmsf::Webdav::Cache.exist?("#{propfind_key}.invalid")
            end
          end
          # Return HTTP code.
          MultiStatus
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
            status
          end
        end
      end

      # Escape URL string
      def url_format(resource)
        ret = resource.public_path
        if resource.collection? && (ret[-1,1] != '/')
          ret += '/'
        end
        Addressable::URI.escape ret
      end

      def url_unescape(str)
        Addressable::URI.unescape str
      end
      
      private
      
      def create_propfind_response(properties)
        # Generate response, is stored in response.body
        render_xml(:multistatus) do |xml|
          find_resources.each do |resource|
            if resource.collection?
              # Index, Project or Folder
              # path is unique enough for the key and is available for all three, and the path doesn't change 
              # for this path as long as it stays. On its path. The path does not stray from its path without 
              # changing its path.
              propstats_key = "PROPSTATS#{resource.path}"
            else
              # File
              # Use file.id & file.last_revision.id as key
              # When revision changes then the key will change and the old cached item will eventually be evicted
              propstats_key = "PROPSTATS/#{resource.resource.file.id}-#{resource.resource.file.last_revision.id}"
            end

            xml_str = RedmineDmsf::Webdav::Cache.read(propstats_key)
            if xml_str.nil?
              # Create the complete PROPSTATS response
              propstats_builder = Nokogiri::XML::Builder.new do |propstats_xml|
                propstats_xml.send('propstat', {'xmlns:D' => 'DAV:'}.merge(resource.root_xml_attributes)) do
                  propstats_xml.parent.namespace = propstats_xml.parent.namespace_definitions.first
                  xml2 = propstats_xml['D']
                  
                  xml2.response do
                    unless(resource.propstat_relative_path)
                      xml2.href "#{scheme}://#{host}:#{port}#{url_format(resource)}"                  
                    else
                      xml2.href url_format(resource)
                    end
                    propstats(xml2, get_properties(resource, properties.empty? ? resource.properties : properties))
                  end
                end
              end

              # Just want to add the <:D:response> so extract it.
              # Q: Is there a better/faster way to do this?
              xml_str = Nokogiri::XML.parse(propstats_builder.to_xml).xpath('//D:response').first.to_xml
              
              # Add PROPSTATS to cache
              # Caching the PROPSTATS response as xml text string.
              RedmineDmsf::Webdav::Cache.write(propstats_key, xml_str)
            end
            xml << xml_str
          end
        end
      end
      
    end
  end
end
