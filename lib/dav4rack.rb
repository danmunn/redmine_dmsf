require 'time'
require 'uri'
require 'nokogiri'
require 'ox'

require 'rack'
require 'dav4rack/utils'
require 'dav4rack/http_status'
require 'dav4rack/resource'
require 'dav4rack/handler'
require 'dav4rack/controller'

module DAV4Rack
  IS_18 = RUBY_VERSION[0,3] == '1.8'
end
