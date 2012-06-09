module RedmineDmsf
  module Webdav
    class BaseResource < DAV4Rack::Resource

      DIR_FILE = "<tr><td class=\"name\"><a href=\"%s\">%s</a></td><td class=\"size\">%s</td><td class=\"type\">%s</td><td class=\"mtime\">%s</td></tr>"

      def initialize(public_path, path, request, response, options)
        super(public_path, path, request, response, options)
      end

      def accessor=(klass)
        @__proxy = klass
      end

      def long_name
        nil
      end

      def special_type
        nil
      end

      def html_display

        @response.body = ""
        Confict unless collection?
        entities = children.map{|child| DIR_FILE % [child.public_path.html_safe, child.long_name || child.name, "-", child.special_type || child.content_type, child.last_modified]} * "\n"
        @response.body << index_page % [ path.empty? ? "/" : path, path.empty? ? "/" : path , entities ]
      end

      def child(name, options = nil)
        @__proxy.child(name)
      end

      def index_page
        return <<-PAGE
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body></html>
        PAGE
      end

      protected
      def Project
        return @Project unless @Project.nil?
        pinfo = @path.split('/').drop(1)
        if pinfo.length > 0
          begin
            @project = Project.find(pinfo.first)
          rescue
          end
        end
      end
    end
  end
end


