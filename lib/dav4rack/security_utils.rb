require 'digest'

module DAV4Rack

  # Implements secure string comparison methods.
  # Taken straight from ActiveSupport
  module SecurityUtils
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
    module_function :secure_compare

    def variable_size_secure_compare(a, b)
      secure_compare(::Digest::SHA256.hexdigest(a), ::Digest::SHA256.hexdigest(b))
    end
    module_function :variable_size_secure_compare
  end
end
