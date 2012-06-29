vendor = File.expand_path('../vendor', __FILE__)
$:.unshift(vendor) unless $:.include?(vendor)
require 'dav4rack'
