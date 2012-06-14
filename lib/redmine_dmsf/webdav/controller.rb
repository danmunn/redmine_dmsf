module RedmineDmsf
  module Webdav
    class Controller < DAV4Rack::Controller

      #Overload default options
      def options
        response["Allow"] = 'OPTIONS,HEAD,GET,PUT,POST,DELETE,PROPFIND,PROPPATCH,MKCOL,COPY,MOVE,LOCK,UNLOCK'
        response["Dav"] = "1,2,3"
        response["Ms-Author-Via"] = "DAV"
        OK
      end

      #Overload the default propfind function with this
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

    end
  end
end
