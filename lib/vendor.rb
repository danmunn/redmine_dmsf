#Calculate path to vendor and subsequently add it to include path
vendor = File.expand_path('../vendor', __FILE__)
$:.unshift(vendor) unless $:.include?(vendor)