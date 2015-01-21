require 'rubygems'
require 'active_resource'

# Dmsf file
class DmsfFile < ActiveResource::Base
  self.site = 'http://localhost:3000/'
  self.user = '***'
  self.password = '***'
end

# Retrieving a file
file = DmsfFile.find 1
if file
  puts file.name
else
  puts 'No file with id = 1 found'
end
